set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

confirm=`tiup_confirm_str "${env}"`
name=`must_env_val "${env}" 'tidb.cluster'`

keep_monitor=`must_env_val "${env}" 'tidb.op.keep-monitor'`
keep_monitor=`to_true "${keep_monitor}"`

exist=`cluster_exist "${name}"`
if [ "${exist}" == 'false' ]; then
	echo "[:-] cluster name '${name}' not exists" >&2
	exit
fi

keep_prom_str=" --retain-role-data prometheus"
if [ "${keep_monitor}" != 'true' ]; then
	keep_prom_str=''
fi

tiup cluster --format=plain destroy "${name}"${confirm}${keep_prom_str}
