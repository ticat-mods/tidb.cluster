set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

key="${1}"
if [ -z "${key}" ]; then
	echo "[:(] arg 'key' is empty, exit" >&2
	exit 1
fi

pp=`env_val "${env}" "${key}"`
echo "${key} = ${pp}"
