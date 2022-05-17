function verify_mysql()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	set +e
	MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}" -e "show databases" >/dev/null 2>&1
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
	local pp="${4}"
	local timeout="${5}"

	for ((i=0; i < ${timeout}; i++)); do
		set +e
		MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}" -e "show databases" #>/dev/null 2>&1
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
	local pp="${5}"
	echo "[:)] setup mysql access to env" >&2
	echo "mysql.host=${host}" >> "${env_file}"
	echo "mysql.port=${port}" >> "${env_file}"
	echo "mysql.user=${user}" >> "${env_file}"
	echo "mysql.pwd=${pp}" >> "${env_file}"
	echo "    - mysql.host = ${host}"
	echo "    - mysql.port = ${port}"
	echo "    - mysql.user = ${user}"
	echo "    - mysql.pwd = ***"
}
