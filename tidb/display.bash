set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

plain=`tiup_output_fmt_str "${env}"`
name=`must_env_val "${env}" 'tidb.cluster'`

tiup cluster${plain} display "${name}"
