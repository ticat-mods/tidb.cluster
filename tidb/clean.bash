set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

plain=`tiup_output_fmt_str "${env}"`
confirm=`tiup_confirm_str "${env}"`

name=`must_env_val "${env}" 'tidb.cluster'`
exist=`cluster_exist "${name}"`
if [ "${exist}" == 'false' ]; then
	echo "[:-] cluster '${name}' not exist, skipped"
	exit
fi

keep_prom=" --ignore-role prometheus"
tiup cluster${plain} clean --all "${name}"${confirm}${keep_prom}
