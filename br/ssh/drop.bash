set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`
shift

# export: $pri_key, $user, $cnt, $hosts, $deploy_dirs, $data_dirs
get_instance_info "${env}" 'false'

tag=`must_env_val "${env}" 'tidb.data.tag'`

for (( i = 0; i < ${cnt}; ++i)) do
	host="${hosts[$i]}"
	data_dir="${data_dirs[$i]}"
	deploy_dir="${deploy_dirs[$i]}"
	dir=`choose_backup_dir "${data_dir}" "${deploy_dir}"`

	echo "[:-] '${host}:${dir}.${tag}' remove backup dir begin"
	ssh_exe "${host}" "rm -rf \"${dir}.${tag}\""
	echo "[:)] '${host}:${dir}.${tag}' remove backup dir done"
done
