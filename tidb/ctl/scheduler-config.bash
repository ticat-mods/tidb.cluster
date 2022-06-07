set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

scheduler="${1}"
config="${2}"
value="${3}"

version=`env_val "${env}" 'tidb.version'`
if [ -z "${version}" ]; then
    name=`must_env_val "${env}" 'tidb.cluster'`
    version=`must_cluster_version "${name}"`
fi

pd_addr="${5}"
if [ -z "${pd_addr}" ]; then
    name=`must_env_val "${env}" 'tidb.cluster'`
    pd_addr=`must_pd_addr "${name}"`
fi

tiup ctl:${version} pd -u "${pd_addr}" scheduler config "${scheduler}" set "${config}" "${value}"
