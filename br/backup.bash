set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`
shift

## Handle args
#
name=`must_env_val "${env}" 'tidb.cluster'`
pd=`must_cluster_pd "${name}"`

threads=`must_env_val "${env}" 'br.threads'`

dir=`must_env_val "${env}" 'br.backup-dir'`

exist_policy=`must_env_val "${env}" 'tidb.backup.exist-policy'`
if [ "${exist_policy}" != 'skip' ] && [ "${exist_policy}" != 'overwrite' ] && [ "${exist_policy}" != 'error' ]; then
	echo "[:(] invalid exist-policy: '${exist_policy}', should be skip|overwrite|error" >&2
	exit 1
fi

## Handle existed data
#
if [ -f "${dir}/backupmeta" ]; then
	if [ "${exist_policy}" == 'skip' ]; then
		echo "[:-] '${dir}' data exist, skipped"
		exit 0
	elif [ "${exist_policy}" == 'error' ]; then
		echo "[:(] '${dir}' data exist, can't overwrite"
		exit 1
	else
		if [ -z "${dir}" ]; then
			echo "[:(] looks strange, can't remove '${dir}'"
			exit 1
		fi
		echo "[:-] '${dir}' data exist, removing"
		rm -rf "${dir}"
	fi
fi

checksum=`must_env_val "${env}" 'br.checksum'`
checksum=`to_true "${checksum}"`
if [ "${checksum}" == 'true' ]; then
	checksum=" "
else
	checksum=" --checksum=false"
fi

target=`env_val "${env}" 'br.target'`
if [ -z "${target}" ] || [ "${target}" == '-full' ] || [ "${target}" == '--full' ]; then
	target="full"
else
	target="db --db ${target}"
fi

# TODO: get user name from tiup
mkdir -p "${dir}"
set +e 
chown -R tidb "${dir}"
sudo chown -R tidb "${dir}" < /dev/null
set -e

br_bin=`must_env_val "${env}" 'br.bin'`

echo ${br_bin} backup ${target} --pd "${pd}" -s "${dir}" --check-requirements=false${checksum} --concurrency "${threads}"
${br_bin} backup ${target} --pd "${pd}" -s "${dir}" --check-requirements=false${checksum} --concurrency "${threads}"
