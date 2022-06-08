set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

# export: $pri_key, $user, $cnt, $hosts, $deploy_dirs, $data_dirs
get_instance_info "${env}" 'true'

tag=`must_env_val "${env}" 'tidb.data.tag'`

db_user=`env_val "${env}" 'mysql.user'`
db_root_pwd=''

deploy_to_user=`must_env_val "${env}" 'deploy.to-user'`
deploy_user=`must_env_val "${env}" 'deploy.user'`

for (( i = 0; i < ${cnt}; ++i)) do
	host="${hosts[$i]}"
	data_dir="${data_dirs[$i]}"
	deploy_dir="${deploy_dirs[$i]}"
	dir=`choose_backup_dir "${data_dir}" "${deploy_dir}"`

	echo "[:-] restore '${host}:${dir}' from tag '${tag}' begin"
	cmd="sudo rm -rf \"${dir}\" && sudo rm -f \"${dir}.${tag}/space_placeholder_file\" && sudo cp -rp \"${dir}.${tag}\" \"${dir}\" && sudo chown -R \"${deploy_to_user}\" \"${dir}\""
	ssh_exe "${host}" "${cmd}" "${deploy_user}"

	if [ "${db_user}" == 'root' ] && [ -z "${db_root_pwd}" ]; then
		cmd="sudo touch \"${dir}/db_root_pwd\" && sudo cat \"${dir}/db_root_pwd\""
		db_root_pwd=`ssh_exe "${host}" "${cmd}" "${deploy_user}"`
		if [ ! -z "${db_root_pwd}" ]; then
			echo "mysql.pwd=${db_root_pwd}" >> "${env_file}"
			echo "[:)] retrieved database root password from backup"
		fi
	fi

	echo "[:)] restore '${host}:${dir}' from tag '${tag}' finish"
done
