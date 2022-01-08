set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`

phrase=`env_val "${env}" 'ssh.pwd'`
hosts=`must_env_val "${env}" 'deploy.hosts'`
hosts=(`list_to_array "${hosts}"`)

ssh_auto_auth "${phrase}" "${hosts[@]}"
