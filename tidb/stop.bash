set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

confirm=`confirm_str "${env}"`
name=`must_env_val "${env}" 'tidb.cluster'`

# Not stop: prometheus,grafana
roles="pd,tikv,pump,tidb,tiflash,drainer,cdc,alertmanager,tispark-master,tispark-worker"
tiup cluster stop "${name}"${confirm} --role ${roles}
