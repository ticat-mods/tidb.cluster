set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`
shift

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`
pp=`env_val "${env}" 'mysql.pwd'`

shift 4
verify=`to_false "${1}"`

if [ "${verify}" != 'false' ]; then
	verify_mysql "${host}" "${port}" "${user}" "${pp}"
fi
