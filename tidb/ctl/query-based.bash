set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

name=`must_env_val "${env}" 'tidb.cluster'`

version=`env_val "${env}" 'tidb.version'`
if [ -z "${version}" ]; then
    version=`must_cluster_version "${name}"`
fi

pd_leader_id=`must_pd_leader_id "${name}"`

tiup ctl:${version} pd -u "${pd_leader_id}" scheduler config balance-hot-region-scheduler set write-leader-priorities query,byte
tiup ctl:${version} pd -u "${pd_leader_id}" scheduler config balance-hot-region-scheduler set strict-picking-store false
