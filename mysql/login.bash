set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat ${1}/env`
shift

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

pp=`env_val "${env}" 'mysql.pwd'`

# TODO: auto use the only one database
db="${4}"
if [ ! -z "${db}" ]; then
	db=" --database=${db}"
else
	db=''
fi

MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}" --comments${db}
