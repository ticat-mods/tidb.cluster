set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

name=`must_env_val "${env}" 'tidb.cluster'`
host=`must_env_val "${env}" 'tidb.node.host'`
port=`must_env_val "${env}" 'tidb.node.port'`
shift 3

version=`env_val "${env}" 'tidb.version'`
if [ -z "${version}" ]; then
    version=`must_cluster_version "${name}"`
fi

address="${host}:${port}"
pd_leader_id=`must_pd_leader_id "${name}"`
store_id=`must_store_id "${pd_leader_id}" "${version}" "${address}"`

tiup ctl:${version} pd -u "${pd_leader_id}" \
    scheduler add evict-leader ${store_id}
