set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`
shift

plain=`tiup_output_fmt_str "${env}"`

confirm=`tiup_confirm_str "${env}"`
name=`must_env_val "${env}" 'tidb.cluster'`

shift 2
force=`tiup_maybe_enable_opt "${1}" '--force'`
skip_restart=`tiup_maybe_enable_opt "${2}" '--skip-restart'`
roles=''

# remove roles' whitespace
if [ ! -z "${3// }" ]; then
	roles=" --role ${3// }"
fi

tiup cluster${plain} reload "${name}" ${force}${skip_restart}${roles}${confirm}
