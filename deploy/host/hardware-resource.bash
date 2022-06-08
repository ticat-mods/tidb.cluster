set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

deploy_user=`must_env_val "${env}" 'deploy.user'`

hosts=`must_env_val "${env}" 'deploy.hosts'`
hosts=$(echo "${hosts}" | tr "," "\n")

py=`must_env_val "${env}" 'sys.ext.exec.py'`

for host in ${hosts[@]}; do
	echo "==> ${host}"

	disks=`ssh_exe "${host}" "sudo lsblk -rbo NAME,TYPE,FSTYPE,SIZE,PKNAME,RM,MOUNTPOINT" "${deploy_user}"`
	echo 'lsblk -rbo NAME,TYPE,FSTYPE,SIZE,PKNAME,RM,MOUNTPOINT'
	echo "${disks}" | awk '{print "    "$0}'
	set +e
	disks_used=`ssh_exe "${host}" "sudo df --output=source,avail,target" "${deploy_user}"`
	set -e
	echo 'df --output=source,avail,target'
	echo "${disks_used}" | awk '{print "    "$0}'
	selecteds=`"${py}" "${here}/select_disk.py" "${disks}" "${disks_used}"`
	disk_names=`echo "${selecteds}" | { grep avail || test $? = 1; } | awk -F '.' '{print $2}' | uniq`
	disk_names=`lines_to_list "${disk_names}"`

	echo 'output env:'
	if [ ! -z "${selecteds}" ]; then
		echo "${selecteds}" | awk '{print "deploy.host.resource.'${host}'."$0}' | tee -a "${env_file}" | awk '{print "    "$0}'
	fi
	echo "deploy.host.resource.${host}.devs=${disk_names}" | tee -a "${env_file}" | awk '{print "    "$0}'

	vc=`ssh_exe "${host}" "sudo grep -c processor /proc/cpuinfo" "${deploy_user}"`
	echo "deploy.host.resource.${host}.vcores=${vc}" | tee -a "${env_file}" | awk '{print "    "$0}'

	numa=''
	if [ -x "$(command -v numactl)" ]; then
		set +e
		numa=`numactl --hardware|grep cpus|awk '{print $2}'`
		set -e
		numa=`lines_to_list "${numa}"`
	fi
	echo "deploy.host.resource.${host}.numa=${numa}" | tee -a "${env_file}" | awk '{print "    "$0}'

	mem=`ssh_exe "${host}" "sudo free -g | grep Mem | awk '{print \\$2}'" "${deploy_user}"`
	echo "deploy.host.resource.${host}.mem-gb=${mem}" | tee -a "${env_file}" | awk '{print "    "$0}'
	echo
done
