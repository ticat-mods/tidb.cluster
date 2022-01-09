set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

prefix="${1}"
user="${2}"
group="${3}"

hosts=`must_env_val "${env}" 'deploy.hosts'`
hosts=`list_to_array "${hosts}"`

function auto_mount()
{
	local host="${1}"
	local dev="${2}"
	local fs="${3}"
	if [ -z "${fs}" ]; then
		echo "  > auto format and mount: ${dev} at ${host}"
	else
		echo "  > auto mount: ${dev}(${fs}) at ${host}"
	fi

	if [ -z "${fs}" ]; then
		echo "    - format ${dev} to ext4: start"
		ssh_exe "${host}" "sudo mkfs.ext4 -F -t ext4 \"/dev/${dev}\"" 2>&1 | awk '{print "    "$0}'
		echo "    - format ${dev} to ext4: done"
	fi

	for (( i=1; i<99; i++ )); do
		local dir="${prefix}${i}"
		echo "    - ${dir}:"
		set +e
		local exists=`ssh_exe "${host}" "test -d \"${dir}\" && echo yes"`
		set -e
		if [ "${exists}" == 'yes' ]; then
			echo "        exists, checking mounting info"
			local mounted=`ssh_exe "${host}" "mount | awk '{if (\\$3 == \"${dir}\") {print \"yes\"; exit 0}} ENDFILE {print \"no\"}'"`
			if [ "${mounted}" != 'no' ]; then
				echo "        mounted, skipped"
				continue
			else
				echo "        with no mounting info"
			fi
		fi

		echo "        make sure exists and belong to ${user}:${group}"
		ssh_exe "${host}" "mkdir -p \"${dir}\" && chown \"${user}\":\"${group}\" \"${dir}\""
		echo "        owner check done"

		echo "        mounting ${dev}"
		ssh_exe "${host}" "sudo mount -o nodiratime,noatime -t ext4 \"/dev/${dev}\" \"${dir}\"" | awk '{print "        "$0}'
		echo "        mounted"
		return
	done

	echo "    [:(] try too many times and failed"
	return 1
}

for host in ${hosts[@]}; do
	devs_str=`env_val "${env}" "deploy.host.resource.${host}.devs"`
	if [ -z "${devs_str}" ]; then
		continue
	fi
	devs=`list_to_array "${devs_str}"`
	for dev in ${devs[@]}; do
		dev_key="deploy.host.resource.${host}.dev.${dev}"
		fs=`env_val "${env}" "${dev_key}.fs"`
		mounted=`env_val "${env}" "${dev_key}.mounted"`
		if [ -z "${mounted}" ]; then
			auto_mount "${host}" "${dev}" "${fs}"
		fi
	done
	echo "==> ${host}: all mounted: ${devs_str}"
done
