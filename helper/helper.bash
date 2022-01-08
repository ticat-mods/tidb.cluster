 . "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/bash.helper/helper.bash"
 . "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/tiup.helper/tiup.bash"

 . "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/ssh.bash"
 . "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/mysql.bash"


function timestamp()
{
	echo `date +%s`
}

function choose_backup_dir()
{
	local data_dir_origin="${1}"
	local deploy_dir_origin="${2}"

	local data_dir="${1}"
	local deploy_dir="${2}"
	# TODO: move OS detecting to ticat.helper.bash
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
