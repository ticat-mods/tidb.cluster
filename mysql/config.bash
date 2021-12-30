set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`
shift

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

shift 3
verify=`to_false "${1}"`

if [ "${verify}" != 'false' ]; then
	verify_mysql "${host}" "${port}" "${user}"
fi
