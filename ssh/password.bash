set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"

echo -n "password to be set to env 'ssh.pwd':"
read -s phrase
echo "ssh.pwd=${phrase}" >> "${env_file}"
echo
