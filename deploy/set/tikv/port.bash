set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../../helper/helper.bash"

env_file="${1}/env"
shift

port_name="${1}"
port="${2}"
instance="${3}"

if [ -z "${port_name}" ]; then
	echo "arg 'port-name' is empty" >&2
	exit 1
fi
if [ -z "${port}" ]; then
	echo "arg 'port' is empty" >&2
	exit 1
fi
if [ ! -z "${instance}" ]; then
	instance="${instance}."
fi
echo "deploy.port.tikv.${instance}${port_name}=${port}" | tee -a "${env_file}"
