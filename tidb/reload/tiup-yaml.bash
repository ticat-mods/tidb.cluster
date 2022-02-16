set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`
shift

plain=`tiup_output_fmt_str "${env}"`

confirm=`tiup_confirm_str "${env}"`
name=`must_env_val "${env}" 'tidb.cluster'`
yaml=`must_env_val "${env}" 'tidb.tiup.yaml'`

shift 3
force=`tiup_maybe_enable_opt "${1}" '--force'`
skip_restart=`tiup_maybe_enable_opt "${2}" '--skip-restart'`

roles=''
if [ ! -z "${3}" ]; then
	roles=" --role ${3}"
fi

editor="${session}/edit-tiup-yaml-${RANDOM}.bash"
echo "cat \"${yaml}\" > \"\${1}\"" > "${editor}"

echo "${editor}:`cat ${editor}`"

EDITOR="${editor}" tiup cluster${plain} reload "${name}" ${force}${skip_restart}${roles}${confirm}
