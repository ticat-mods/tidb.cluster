set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

prefix="${1}"
user=`must_env_val "${env}" 'deploy.user'`
group="${user}"

hosts=`must_env_val "${env}" 'deploy.hosts'`
hosts=`list_to_array "${hosts}"`

function auto_mount()
{
	local host="${1}"
	local dev="${2}"
	local fs="${3}"
	if [ -z "${fs}" ]; then
		echo "--> ${host}: auto format and mount ${dev}"
	else
		echo "--> ${host}: auto mount ${dev}(${fs})"
	fi

	if [ -z "${fs}" ]; then
		echo "    * format ${dev} to ext4: start"
		ssh_exe "${host}" "sudo mkfs.ext4 -F -t ext4 \"/dev/${dev}\"" 2>&1 | awk '{print "    "$0}'
		echo "    * format ${dev} to ext4: done"
	fi

	for (( i=1; i<99; i++ )); do
		local dir="${prefix}${i}"
		echo "    [${dir}]"
		set +e
		local exists=`ssh_exe "${host}" "sudo test -d \"${dir}\" && echo yes"`
		set -e
		if [ "${exists}" == 'yes' ]; then
			echo "        exists, checking mounting info"
			local mounted=`ssh_exe "${host}" "sudo mount | awk '{if (\\$3 == \"${dir}\") {print \"yes\"; exit 0}} ENDFILE {print \"no\"}'"`
			if [ "${mounted}" != 'no' ]; then
				echo "        mounted to other dev, skipped"
				continue
			else
				echo "        - no mounting info"
			fi
			echo "        check owner"
			local owner=`ssh_exe "${host}" "sudo ls -ld \"${dir}\" | awk {print \\$3}"`
			if [ "${owner}" == "${user}" ]; then
				echo "        - owner is ${user}"
			else
				echo "        - owner is not ${user}"
			fi
		else
			echo "        create and chown to ${user}:${group}"
			ssh_exe "${host}" "sudo mkdir -p \"${dir}\" && sudo chown -R \"${user}\":\"${group}\" \"${dir}\""
			echo "        - done"
		fi

		echo "        mounting ${dev}"
		ssh_exe "${host}" "sudo mount -o nodelalloc,nodiratime,noatime -t ext4 \"/dev/${dev}\" \"${dir}\"" | awk '{print "        "$0}'
		echo "        - mounted"

		echo "        write back to env"
		echo "deploy.host.resource.${host}.dev.${dev}=${dir}" | tee -a "${env_file}" | awk '{print "        - "$0}'
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
		if [ ! -z "${mounted}" ]; then
			continue
		fi
		if [ "${fs}" == 'BitLocker' ]; then
			continue
		fi
		auto_mount "${host}" "${dev}" "${fs}"
	done
	echo "==> ${host}: all mounted: ${devs_str}"
done
