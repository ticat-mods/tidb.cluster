set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/ssh.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`

phrase=`must_env_val "${env}" 'ssh.pwd'`
yaml=`must_env_val "${env}" 'tidb.tiup.yaml'`
hosts=(`cat "${yaml}" | { grep 'host:' || test $? = 1; } | awk -F 'host:' '{print $2}' | sort | uniq`)

ssh_auto_auth "${hosts[@]}"
