set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`
shift

confirm=`tiup_confirm_str "${env}"`
name=`must_env_val "${env}" 'tidb.cluster'`
shift

if [[ `tiup cluster --version | awk '/tiup/{print $3}'` < '1.7.0' ]]; then
    cluster_info=`tiup cluster display ${name} -R tikv --json 2>/dev/null`
else
    cluster_info=`tiup cluster display ${name} -R tikv --format json 2>/dev/null`
fi
num_tikvs=`echo "${cluster_info}" | jq --raw-output ".instances | length"`
selected_tikv_index=$(($RANDOM % ${num_tikvs}))
tikv_node_id=`echo "${cluster_info}" | jq --raw-output --argjson v "${selected_tikv_index}" '.instances[$v].id'`
tikv_node_host=`echo "${cluster_info}" | jq --raw-output --argjson v "${selected_tikv_index}" '.instances[$v].host'`
tikv_port=`echo "${cluster_info}" | jq --raw-output --argjson v "${selected_tikv_index}" '.instances[$v].Port'`

tiup cluster stop ${name} -R tikv -N "${tikv_node_id}" ${confirm}
echo "tidb.node.killed.host=${tikv_node_host}" >> "${session}/env"
echo "tidb.node.killed.port=${tikv_port}" >> "${session}/env"
