set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/build-and-patch.bash"

env=`cat "${1}/env"`
shift

repo="${1}"
branch="${2}"
git_hash="${3}"

tidb_component_build_and_patch "${env}" "${repo}" "${branch}" "${git_hash}" 'pd' 'bin/pd-server' 'make'
