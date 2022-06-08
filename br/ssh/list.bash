set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env=`cat "${1}/env"`

# export: $pri_key, $user, $cnt, $hosts, $deploy_dirs, $data_dirs
get_instance_info "${env}" 'false'

for (( i = 0; i < ${cnt}; ++i)) do
	host="${hosts[$i]}"
	data_dir="${data_dirs[$i]}"
	deploy_dir="${deploy_dirs[$i]}"
	dir=`choose_backup_dir "${data_dir}" "${deploy_dir}"`

	# TODO: need sudo in the cmd
	tags=`ssh_exe "${host}" 'for f in "'${dir}'".*; do echo "${f##*.}"; done'`
	if [ -z "${tags}" ] || [ "${tags}" == '*' ]; then
		echo "[:)] '${host}:${dir}' has not backup tags"
		continue
	fi

	echo "[:)] '${host}:${dir}' has backup tags:"
	echo "${tags}" | awk '{print "      "$0}'
done
