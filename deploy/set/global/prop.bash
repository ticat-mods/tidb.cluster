set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../../helper/helper.bash"

env_file="${1}/env"
shift

key="${1}"
val="${2}"

if [ -z "${key}" ]; then
	echo "arg key is empty" >&2
	exit 1
fi
if [ -z "${val}" ]; then
	echo "arg value is empty" >&2
	exit 1
fi

echo "deploy.prop.global.${key}=${val}" | tee -a "${env_file}"
