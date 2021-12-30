set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
shift

prefix='tidb'

user="${1}"
if [ "${user}" != 'tidb' ]; then
	echo "${prefix}.mod.global.user=${user}" | tee -a "${env_file}"
fi

group="${2}"
if [ "${group}" != 'tidb' ]; then
	echo "${prefix}.mod.global.group=${group}" | tee -a "${env_file}"
fi

ssh_port="${3}"
if [ "${ssh_port}" != '22' ]; then
	echo "${prefix}.mod.global.ssh_port=${ssh_port}" | tee -a "${env_file}"
fi

deploy_dir="${4}"
if [ "${deploy_dir}" != '/tidb-deploy' ]; then
	echo "${prefix}.mod.global.deploy_dir=${deploy_dir}" | tee -a "${env_file}"
fi

data_dir="${5}"
if [ "${data_dir}" != '/tidb-data' ]; then
	echo "${prefix}.mod.global.data_dir=${data_dir}" | tee -a "${env_file}"
fi

arch="${6}"
if [ "${arch}" != 'amd64' ]; then
	echo "${prefix}.mod.global.arch=${arch}" | tee -a "${env_file}"
fi
