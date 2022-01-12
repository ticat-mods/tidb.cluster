set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`

endpoint=`must_env_val "${env}" 'br.endpoint'`
username=`must_env_val "${env}" 'br.username'`
password=`must_env_val "${env}" 'br.password'`
name=`must_env_val "${env}" 'tidb.cluster'`
pd=`must_cluster_pd "${name}"`

threads=`must_env_val "${env}" 'br.threads'`

dir=`must_env_val "${env}" 'br.backup-dir'`

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

br_bin=`must_env_val "${env}" 'br.bin'`

echo ${br_bin} restore ${target} --pd "${pd}" --s3.endpoint "${endpoint}" -s "s3://${dir}" --check-requirements=false${checksum} --concurrency "${threads}"
env AWS_ACCESS_KEY_ID="${username}" \
	AWS_SECRET_ACCESS_KEY="${password}" \
	${br_bin} restore ${target} \
		--pd "${pd}" \
		--s3.endpoint "${endpoint}" \
		-s "s3://${dir}" \
		--check-requirements=false${checksum} \
		--concurrency "${threads}" | tee ${session}/restore-`date +%s`.log 2>&1
echo "[:)] restored"
