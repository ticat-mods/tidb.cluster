set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

shift
user="${1}"
roles="${2}"

auto_conf_mysql=`must_env_val "${env}" 'tidb.auto-config-mysql'`
auto_conf_mysql=`to_true "${auto_conf_mysql}"`

name=`must_env_val "${env}" 'tidb.cluster'`
if [ -z "${roles}" ]; then
	tiup cluster --format=plain start "${name}"
else
	tiup cluster --format=plain start "${name}" --role "${roles}"
fi

tidbs=`must_cluster_tidbs "${name}"`

cnt=`echo "${tidbs}" | wc -l | awk '{print $1}'`

tidb=`echo "${tidbs}" | head -n 1`
host=`echo "${tidb}" | awk -F ':' '{print $1}'`
port=`echo "${tidb}" | awk -F ':' '{print $2}'`

verify_mysql_timeout "${host}" "${port}" "${user}" 16

if [ "${auto_conf_mysql}" == 'true' ]; then
	config_mysql "${env_file}" "${host}" "${port}" "${user}"
	if [ "${cnt}" != 1 ]; then
		echo "[:-] more than 1 tidb found(${cnt}) in cluster '${name}', select the first one" >&2
	fi
fi
