set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

phrase=`env_val "${env}" 'ssh.pwd'`
deploy_user=`must_env_val "${env}" 'deploy.user'`
hosts=`must_env_val "${env}" 'deploy.hosts'`
hosts=(`list_to_array "${hosts}"`)

curr_user=`whoami`
ssh_auto_auth "${curr_user}" "${phrase}" "${hosts[@]}"

if [ "${curr_user}" != "${deploy_user}" ]; then
	ssh_auto_auth "${deploy_user}" "${phrase}" "${hosts[@]}"
fi

echo "ssh.pwd=--" >> "${env_file}"
