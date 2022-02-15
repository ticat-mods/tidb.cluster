function gen_dir_by_component_name()
{
	local name="${1}"
	local branch="${2}"
	local git_hash="${3}"
	if [ ! -z "${branch}" ]; then
		local branch=`echo "${branch}" | tr '.' '-' | tr '/' '-'`
		local name="${name}.${branch}"
	fi
	if [ ! -z "${git_hash}" ]; then
		local name="${name}.${git_hash}"
	fi
	echo "${name}"
}

function tidb_component_build_and_patch()
{
	local env="${1}"

	local repo="${2}"
	if [ -z "${repo}" ]; then
		echo "[:(] arg 'git-repo' is empty, exited" >&2
		return 1
	fi
	local repo=`normalize_github_addr "${repo}"`

	local branch="${3}"
	local git_hash="${4}"

	local dir_name="${5}"
	if [ -z "${dir_name}" ]; then
		echo "[:(] arg 'dir-name-in-shared-dir' is empty, exited" >&2
		return 1
	else
		local dir_name=`gen_dir_by_component_name "${dir_name}" "${branch}" "${git_hash}"`
	fi

	local bin_path="${6}"
	if [ -z "${bin_path}" ]; then
		echo "[:(] arg 'bin-path' is empty, exited" >&2
		return 1
	fi

	local make_cmd="${7}"

	local built=`build_bin_in_ticat_shared_dir "${bin_path}" "${repo}" "${env}" "${dir_name}" "${branch}" "${make_cmd}" "${git_hash}"`
	if [ ! -f "${built}" ]; then
		return 1
	fi
	echo "binary: ${built}"

	local plain=`env_val "${env}" 'tidb.tiup.plain-output'`
	local cluster=`must_env_val "${env}" 'tidb.cluster'`

	path_patch "${cluster}" "${built}" "${plain}"
}
