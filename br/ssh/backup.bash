set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../../helper/helper.bash"

env=`cat "${1}/env"`
shift

# export: $pri_key, $user, $cnt, $hosts, $deploy_dirs, $data_dirs
get_instance_info "${env}" 'true'

tag=`must_env_val "${env}" 'tidb.data.tag'`

exist_policy=`must_env_val "${env}" 'tidb.backup.exist-policy'`
if [ "${exist_policy}" != 'skip' ] && [ "${exist_policy}" != 'overwrite' ] && [ "${exist_policy}" != 'error' ]; then
	echo "[:(] invalid exist-policy: '${exist_policy}', should be skip|overwrite|error" >&2
	exit 1
fi

use_mv=`must_env_val "${env}" 'tidb.backup.use-mv'`
use_mv=`to_true "${use_mv}"`

for (( i = 0; i < ${cnt}; ++i)) do
	host="${hosts[$i]}"
	data_dir="${data_dirs[$i]}"
	deploy_dir="${deploy_dirs[$i]}"
	dir=`choose_backup_dir "${data_dir}" "${deploy_dir}"`

	echo "[:-] '${host}:${dir}' backup to tag '${tag}' begin"
	set +e
	exists=`ssh_exe "${host}" "test -d \"${dir}.${tag}\" && echo exists"`
	set -e

	if [ ! -z "${exists}" ]; then
		if [ "${exist_policy}" == 'error' ]; then
			echo "[:(] '${host}:${dir}.${tag}' exists, backup failed"
			exit 1
		elif [ "${exist_policy}" == 'overwrite' ]; then
			echo "[:-] '${host}:${dir}.${tag}' exists, overwriting"
		else
			echo "[:-] '${host}:${dir}.${tag}' exists, skipped"
			continue
		fi
	fi

	cmd="rm -rf \"${dir}.${tag}\" && rm -f \"${dir}/space_placeholder_file\" && rm -f \"${dir}/data/space_placeholder_file\""
	ssh_exe "${host}" "${cmd}"

	if [ "${use_mv}" == 'true' ]; then
		cmd="mv \"${dir}\" \"${dir}.${tag}\""
		ssh_exe "${host}" "${cmd}"
		echo "[:)] '${host}:${dir}' backup to tag '${tag}' finish (mv)"
	else
		cmd="cp -rp \"${dir}\" \"${dir}.${tag}\""
		ssh_exe "${host}" "${cmd}"
		echo "[:)] '${host}:${dir}' backup to tag '${tag}' finish (cp)"
	fi
done
