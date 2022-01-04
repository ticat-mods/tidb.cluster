set -uo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

name=`must_env_val "${env}" 'tidb.cluster'`

tiup cluster display "${name}" 1>/dev/null 2>&1
if [ "${?}" == 0 ]; then
	echo "[:)] cluster '${name}' verify succeeded"
else
	echo "[:(] cluster '${name}' verify failed" >&2
	exit 1
fi
