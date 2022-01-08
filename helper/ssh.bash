function gen_auth_script()
{
	local script="${1}"
	local template="${2}"

	local pri_key="${HOME}/.ssh/id_rsa"
	local pub_key=`cat "${pri_key}.pub"`

	echo "key='${pub_key}'" > "${script}"
	cat "${template}" >> "${script}"
}

function ssh_ensure_key_exists()
{
	local pri_key="${HOME}/.ssh/id_rsa"
	for (( i=0; i<6; i++ )); do
		if [ ! -f "${pri_key}" ]; then
			ssh-keygen -f "${pri_key}" -t rsa -N ''
		else
			break
		fi
	done
}

function ssh_auto_auth()
{
	local phrase="${1}"
	shift
	local hosts=("${@}")

	local need_auth='false'
	for h in ${hosts[@]}; do
		local ssh_ok=`ssh_ping "${h}"`
		if [ "${ssh_ok}" == 'true' ]; then
			continue
		fi
		local need_auth='true'
		break
	done

	if [ "${need_auth}" == 'false' ]; then
		echo "[:)] nothing need to do"
		exit
	fi

	ssh_ensure_key_exists

	local script="/tmp/auto-auth.bash"
	local here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
	gen_auth_script "${script}" "${here}/authorize.template"

	for h in ${hosts[@]}; do
		local ssh_ok=`ssh_ping "${h}"`
		if [ "${ssh_ok}" == 'true' ]; then
			continue
		fi
		echo "[:-] ${h} authorizing"
		#sshpass -p "${phrase}" scp -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" "${script}" "${h}:/tmp/"
		#sshpass -p "${phrase}" ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" "${h}" "bash /tmp/auto-auth.bash"
		if [ -z "${phrase}" ]; then
			echo "[:(] no provided password for host '${h}'"
			return 1
		fi
		sshpass -p "${phrase}" scp -o "StrictHostKeyChecking=no" "${script}" "${h}:/tmp/"
		sshpass -p "${phrase}" ssh -o "StrictHostKeyChecking=no" "${h}" "bash /tmp/auto-auth.bash"
		echo "[:)] ${h} authorized"
	done
}
