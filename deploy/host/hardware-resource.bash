set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

hosts=`must_env_val "${env}" 'deploy.hosts'`
py=`must_env_val "${env}" 'sys.ext.exec.py'`

hosts=$(echo "${hosts}" | tr "," "\n")

for h in ${hosts[@]}; do
	echo "==> ${h}"

	disks=`ssh_exe "${h}" "lsblk -rbo NAME,TYPE,SIZE,PKNAME,RM,MOUNTPOINT"`
	echo "lsblk -rbo NAME,TYPE,SIZE,PKNAME,MOUNTPOINT"
	echo "${disks}" | awk '{print "    "$0}'
	set +e
	disks_used=`ssh_exe "${h}" "df --output=source,avail,target"`
	set -e
	echo "df --output=source,avail,target"
	echo "${disks_used}" | awk '{print "    "$0}'
	selecteds=`"${py}" "${here}/select_disk.py" "${disks}" "${disks_used}"`
	disk_names=`echo "${selecteds}" | grep avail | awk -F '.' '{print $2}' | uniq`
	disk_names=`lines_to_list "${disk_names}"`

	echo
	echo "${selecteds}" | awk '{print "deploy.host.resource.'${h}'."$0}' | tee -a "${env_file}"
	echo "deploy.host.resource.${h}.devs=${disk_names}" | tee -a "${env_file}"

	vc=`ssh_exe "${h}" "grep -c processor /proc/cpuinfo"`
	echo "deploy.host.resource.${h}.vcores=${vc}" | tee -a "${env_file}"

	set +e
	numa=`numactl --hardware|grep cpus|awk '{print $2}'`
	set -e
	numa=`lines_to_list "${numa}"`
	echo "deploy.host.resource.${h}.numa=${numa}" | tee -a "${env_file}"

	mem=`ssh_exe "${h}" "free -g | grep Mem | awk '{print \\$2}'"`
	echo "deploy.host.resource.${h}.mem-gb=${mem}" | tee -a "${env_file}"
	echo
done
