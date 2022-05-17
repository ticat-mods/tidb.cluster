set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

session="${1}"
env_file="${session}/env"
env=`cat "${env_file}"`
shift

shift
user="${1}"
roles="${2}"

init=`must_env_val "${env}" 'tidb.init-start'`
init=`to_true "${init}"`
if [ "${init}" == 'true' ]; then
	init=' --init'
else
	init=''
fi

auto_conf_mysql=`must_env_val "${env}" 'tidb.auto-config-mysql'`
auto_conf_mysql=`to_true "${auto_conf_mysql}"`

plain=`tiup_output_fmt_str "${env}"`

name=`must_env_val "${env}" 'tidb.cluster'`
if [ ! -z "${roles}" ]; then
	roles=" --role ${roles}"
fi

log="${session}/tiup-cluster-start-log.${RANDOM}"
echo tiup cluster${plain} start "${name}"${init}${roles}
tiup cluster${plain} start "${name}"${init}${roles} | tee "${log}"

pp=`cat "${log}" | { grep 'The new password is' || test $? = 1; } | awk -F "'" '{print $2}'`
rm -f "${log}"

tidbs=`must_cluster_tidbs "${name}"`

cnt=`echo "${tidbs}" | wc -l | awk '{print $1}'`

tidb=`echo "${tidbs}" | head -n 1`
host=`echo "${tidb}" | awk -F ':' '{print $1}'`
port=`echo "${tidb}" | awk -F ':' '{print $2}'`

verify_mysql_timeout "${host}" "${port}" "${user}" "${pp}" 16

if [ "${auto_conf_mysql}" == 'true' ]; then
	config_mysql "${env_file}" "${host}" "${port}" "${user}" "${pp}"
	if [ "${cnt}" != 1 ]; then
		echo "[:-] more than 1 tidb found(${cnt}) in cluster '${name}', select the first one" >&2
	fi
fi
