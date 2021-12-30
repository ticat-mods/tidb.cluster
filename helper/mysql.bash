function verify_mysql()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	set +e
	mysql -h "${host}" -P "${port}" -u "${user}" -e "show databases" >/dev/null 2>&1
	local ret_code="${?}"
	set -e
	if [ "${ret_code}" != 0 ]; then
		echo "[:(] access mysql '${user}@${host}:${port}' failed" >&2
		exit 1
	fi
}

function verify_mysql_timeout()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local timeout="${4}"

	for ((i=0; i < ${timeout}; i++)); do
		set +e
		mysql -h "${host}" -P "${port}" -u "${user}" -e "show databases" >/dev/null 2>&1
		if [ "${?}" == 0 ]; then
			set -e
			return
		fi
		sleep 1
		echo "[:-] verifying mysql address '${user}@${host}:${port}'"
	done

	echo "[:(] access mysql '${user}@${host}:${port}' failed" >&2
	exit 1
}

function config_mysql()
{
	local env_file="${1}"
	local host="${2}"
	local port="${3}"
	local user="${4}"
	echo "[:)] setup mysql access to env" >&2
	echo "mysql.host=${host}" >> "${env_file}"
	echo "mysql.port=${port}" >> "${env_file}"
	echo "mysql.user=${user}" >> "${env_file}"
	echo "    - mysql.host = ${host}"
	echo "    - mysql.port = ${port}"
	echo "    - mysql.user = ${user}"
}
