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
			if [ ! -f "${pri_key}.pub" ]; then
				ssh-keygen -y -f "${pri_key}" > "${pri_key}.pub"
			fi
			break
		fi
	done
}

function ssh_auto_auth()
{
	local user="${1}"
	local phrase="${2}"
	local key_file="${3}"
	shift 3
	local hosts=("${@}")

	local need_auth='false'
	for host in ${hosts[@]}; do
		echo "[:-] ssh ping ${user}@${host}"
		local ssh_ok=`ssh_ping "${host}" "${user}"`
		if [ "${ssh_ok}" == 'true' ]; then
			continue
		fi
		echo "ssh ping is-ok = ${ssh_ok}"
		local need_auth='true'
		break
	done

	if [ "${need_auth}" == 'false' ]; then
		echo "[:)] nothing need to do: ${user}@[${hosts[@]}]"
		return
	fi

	ssh_ensure_key_exists

	local script_src="/tmp/auto-auth-to-be-copied.bash"
	local script_dest="/tmp/auto-auth-copied.bash"
	local here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
	gen_auth_script "${script_src}" "${here}/authorize.template"

	local key_arg=''
	if [ ! -z "${key_file}" ]; then
		local key_arg=" -i ${key_file}"
	fi

	for host in ${hosts[@]}; do
		local ssh_ok=`ssh_ping "${host}" "${user}"`
		if [ "${ssh_ok}" == 'true' ]; then
			continue
		fi
		echo "[:-] ${host} authorizing"
		if [ -z "${phrase}" ] && [ -z "${key_file}" ]; then
			echo "[:(] no provided password and key file for host '${host}'"
			return 1
		fi
		echo "[:)] ${host} script coping"
		#echo sshpass -p "${phrase}" ssh${key_arg} -o "StrictHostKeyChecking=no" "${user}@${host}" \
		#	"sudo rm -f \"${script_dest}\""
		sshpass -p "${phrase}" ssh${key_arg} -o "StrictHostKeyChecking=no" "${user}@${host}" \
			"sudo rm -f \"${script_dest}\""
		#echo sshpass -p "***" scp${key_arg} -o "StrictHostKeyChecking=no" "${script_src}" "${user}@${host}:${script_dest}"
		sshpass -p "${phrase}" scp${key_arg} -o "StrictHostKeyChecking=no" "${script_src}" "${user}@${host}:${script_dest}"
		echo "[:)] ${host} script copied"
		#echo sshpass -p "***" ssh${key_arg} -o "StrictHostKeyChecking=no" "${user}@${host}" \
		#	"chown \"${user}:${user}\" \"${script_dest}\" && su ${user} -c \"bash ${script_dest}\""
		sshpass -p "${phrase}" ssh${key_arg} -o "StrictHostKeyChecking=no" "${user}@${host}" \
			"chown \"${user}:${user}\" \"${script_dest}\" && su ${user} -c \"bash ${script_dest}\""
		echo "[:)] ${host} authorized"
	done
}
