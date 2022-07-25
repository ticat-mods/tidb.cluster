set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

scheduler="${1}"
config="${2}"
value="${3}"

version=`must_env_val "${env}" 'tidb.version'`
pd_addr=`must_env_val "${env}" 'tidb.pd'`

tiup ctl:${version} pd -u "${pd_addr}" scheduler config "${scheduler}" set "${config}" "${value}"
