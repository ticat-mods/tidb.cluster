set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env=`cat "${1}/env"`
shift

# export: $pri_key, $user, $cnt, $hosts, $deploy_dirs, $data_dirs
get_instance_info "${env}" 'false'

deploy_user=`must_env_val "${env}" 'deploy.user'`
tag=`must_env_val "${env}" 'tidb.data.tag'`

for (( i = 0; i < ${cnt}; ++i)) do
	host="${hosts[$i]}"
	data_dir="${data_dirs[$i]}"
	deploy_dir="${deploy_dirs[$i]}"
	dir=`choose_backup_dir "${data_dir}" "${deploy_dir}"`

	echo "[:-] '${host}:${dir}.${tag}' remove backup dir begin"
	ssh_exe "${host}" "sudo rm -rf \"${dir}.${tag}\"" "${deploy_user}"
	echo "[:)] '${host}:${dir}.${tag}' remove backup dir done"
done
