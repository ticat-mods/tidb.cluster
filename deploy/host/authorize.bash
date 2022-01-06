set -euo pipefail

here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

session_dir="${1}"
env_file="${session_dir}/env"
env=`cat "${env_file}"`
shift

phrase=`must_env_val "${env}" 'ssh.pwd'`

yaml=`must_env_val "${env}" 'tidb.tiup.yaml'`
hosts=(`cat "${yaml}" | { grep 'host:' || test $? = 1; } | awk -F 'host:' '{print $2}' | sort | uniq`)

need_auth='false'
for h in ${hosts[@]}; do
	ssh_ok=`ssh_ping "${h}"`
	if [ "${ssh_ok}" == 'true' ]; then
		continue
	fi
	need_auth='true'
	break
done

if [ "${need_auth}" == 'false' ]; then
	echo "[:)] need to do nothing"
	exit
fi

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
ssh_ensure_key_exists

function gen_auth_script()
{
	local script="${1}"
	local template="${2}"

	local pri_key="${HOME}/.ssh/id_rsa"
	local pub_key=`cat "${pri_key}.pub"`

	echo "key='${pub_key}'" > "${script}"
	cat "${template}" >> "${script}"
}
script="${session_dir}/auto-auth.bash"
gen_auth_script "${script}" "${here}/authorize.template"

for h in ${hosts[@]}; do
	ssh_ok=`ssh_ping "${h}"`
	if [ "${ssh_ok}" == 'true' ]; then
		continue
	fi
	echo "[:-] ${h} authorizing"
	sshpass -p "${phrase}" scp -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" "${script}" "${h}:/tmp/"
	sshpass -p "${phrase}" ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" "${h}" "bash /tmp/auto-auth.bash"
	echo "[:)] ${h} authorized"
done
