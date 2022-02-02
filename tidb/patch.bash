set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

path="${1}"
if [ -z "${path}" ]; then
	echo "[:(] bin-dir arg is empty" >&2
	exit 1
fi

name=`must_env_val "${env}" 'tidb.cluster'`

path_patch "${name}" "${path}"
