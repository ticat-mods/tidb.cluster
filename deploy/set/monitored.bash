set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
shift

host="${1}"

if [ -z "${host}" ]; then
	echo "[:-(] arg 'host' is empty" >&2
	exit 1
fi

echo "deploy.host.monitored=${host}" | tee -a "${env_file}"
