set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env=`cat "${1}/env"`
shift

tag="${1}"
if [ -z "${tag}" ]; then
	tag=`must_env_val "${env}" 'tidb.data.tag'`
fi

dest_tag="${2}"
if [ -z "${dest_tag}" ]; then
	echo "[:(] arg 'dest-tag' is empty, exit" >&2
	exit 1
fi

if [ "${dest_tag}" == "${tag}" ]; then
	echo "[:(] 'dest-tag' is 'src-tag', exit" >&2
	exit 1
fi

# export: $pri_key, $user, $cnt, $hosts, $deploy_dirs, $data_dirs
get_instance_info "${env}" 'false'

deploy_user=`must_env_val "${env}" 'deploy.user'`

for (( i = 0; i < ${cnt}; ++i)) do
	host="${hosts[$i]}"
	data_dir="${data_dirs[$i]}"
	deploy_dir="${deploy_dirs[$i]}"
	dir=`choose_backup_dir "${data_dir}" "${deploy_dir}"`

	echo "[:-] '${host}:${dir}.${tag}' move backup dir to '${dest_tag}' begin"
	ssh_exe "${host}" "sudo rm -rf \"${dir}.${dest_tag}\" && sudo mv \"${dir}.${tag}\" \"${dir}.${dest_tag}\"" "${deploy_user}"
	echo "[:)] '${host}:${dir}.${tag}' move backup dir to '${dest_tag}' done"
done
