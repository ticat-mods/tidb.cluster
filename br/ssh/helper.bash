function choose_backup_dir()
{
	local data_dir_origin="${1}"
	local deploy_dir_origin="${2}"

	local data_dir="${1}"
	local deploy_dir="${2}"

	# TODO: move OS detecting to helper repo
	if [ "`uname`" == 'Linux' ]; then
		if [ -f "${data_dir}" ] && [ -f "${deploy_dir}" ]; then
			local data_dir=`readlink -f "${data_dir}"`
			local deploy_dir=`readlink -f "${deploy_dir}"`
		fi
	fi

	if [[ "${data_dir}" =~ ^"${deploy_dir}" ]]; then
		echo "${deploy_dir_origin}"
	else
		echo "${data_dir_origin}"
	fi
}

# TODO: this is a mess, split it to multi functions
# export: $pri_key, $user, $cnt, $hosts, $deploy_dirs, $data_dirs
function get_instance_info()
{
	local env="${1}"
	local check_stopped="${2}"

	local name=`must_env_val "${env}" 'tidb.cluster'`

	# tiup bug workaround begin
	set +e
	sleep 5
	tiup cluster display "${name}" 1>/dev/null
	tiup cluster display "${name}" 1>/dev/null
	# tiup bug workaround end

	set +e
	local statuses=`tiup cluster display "${name}" 2>/dev/null`
	set -e
	local instances=`echo "${statuses}" | awk '{if ($2=="pd" || $2=="tikv" || $2=="tiflash" || $2=="tiflash-learner") print $0}'`
	if [ -z "${instances}" ]; then
		tiup cluster display "${name}"
		echo "[:(] can't find storage instances (pd/tikv/tiflash)" >&2
		exit 1
	fi
	cnt=`echo "${instances}" | wc -l`

	# TODO: use this key for ssh
	set +e
	pri_key=`tiup cluster list 2>/dev/null | awk '{if ($1=="'${name}'") print $NF}'`
	set -e

	# TODO: get this from tiup yaml file. and other values like ssh-port
	user='tidb'

	if [ "${check_stopped}" != 'false' ]; then
		local ups=`echo "${instances}" | awk '{print $6}' | { grep 'Up' || test $? = 1; }`
		if [ ! -z "${ups}" ]; then
			echo "[:(] cluster not fully stop as needed" >&2
			exit 1
		fi
	fi

	hosts=(`echo "${instances}" | awk '{print $3}'`)
	deploy_dirs=(`echo "${instances}" | awk '{print $NF}'`)
	data_dirs=(`echo "${instances}" | awk '{print $(NF-1)}'`)

	if [ "${#hosts[@]}" != "${#deploy_dirs[@]}" ]; then
		echo "[:(] hosts count != dirs count, string parsing failed" >&2
		exit 1
	fi
	if [ "${#hosts[@]}" == '0' ]; then
		echo "[:(] hosts count == 0, string parsing failed" >&2
		exit 1
	fi
}
