set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`
plain=`tiup_output_fmt_str "${env}"`

tiup cluster${plain} list
