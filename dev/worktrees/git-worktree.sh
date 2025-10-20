#!/bin/bash -e

main_remote=origin # Hardcoded.
# TODO support running from other folders? Unneded when called from `make`.
orig_main_repo=.
main_repo_name=$(basename $(realpath .))

# Add _one_ slash between ${WORKTREE_TOPIC_PREFIX} and ${topic}:
# Strip trailing slash from $WORKTREE_TOPIC_PREFIX
# ${WORKTREE_TOPIC_PREFIX%/} is WORKTREE_TOPIC_PREFIX after stripping any trailing slash
WORKTREE_TOPIC_PREFIX=${WORKTREE_TOPIC_PREFIX%/}
prefix_branch_name() {
	topic=$1
	if echo ${topic} | grep -q '/'; then
		echo ${topic}
	else
		# ${WORKTREE_TOPIC_PREFIX:+/} is a slash if WORKTREE_TOPIC_PREFIX is not empty.
		echo ${WORKTREE_TOPIC_PREFIX}${WORKTREE_TOPIC_PREFIX:+/}${topic}
	fi
}

usage() {
	# Useful when running './support/git-worktree.sh -h'.
	[ -z "$WORKTREE_TOPIC_PREFIX" ] && WORKTREE_TOPIC_PREFIX="\${WORKTREE_TOPIC_PREFIX}"
	cat <<-EOF
		$0 [-n|-qt] [--] command topic [repo_relpath branch]

		The command can be add, remove, force_remove or clean.
		Arguments '\${repo_relpath}' and '\${branch}' are required for
		all commands but 'clean'.

		add

		  Add a new git worktree for '\${repo_relpath}' in '${main_repo_name}-\${topic}/\${repo_relpath}':
		  - create a fresh branch '$(prefix_branch_name \${topic})' tracking '${main_remote}/\${branch}';
		  - check it out in fresh git worktree '${main_repo_name}-\${topic}/\${repo_relpath}'.

		remove

		  Remove the worktree-based clone of '\${repo_relpath}' and branch '$(prefix_branch_name \${topic})',
		  and updates git metadata. Continues if the worktree was partially removed.

		force_remove

		  Like remove, but force removing branch '$(prefix_branch_name \${topic})',
		  even if unmerged. The branch can only be recovered via 'git reflog'.

		clean
		  Run \`make clean\` in the worktree

		post_create
		  Hook to run post setup: Copy configuration files, clone submodules, etc.

		Options:
		  -n	dry run: do not run the commands
		  -q	quiet run: do not display the commands (incompatible with -n)
		  -t	set upstream tracking branches during \`add\` (incompatible with -n)

		Environment variables:

		  WORKTREE_TOPIC_PREFIX

		    Prefix used in '$(prefix_branch_name \${topic})'.
		    We ensure exactly one slash appears between \${WORKTREE_TOPIC_PREFIX} and \${topic}.

		Example:
		  $0 -n fm-42
	EOF
	exit 1
}

usage_error() {
	echo -e ">>>> Usage error: $1\n"
	usage
}

demand_arg() {
	usage_error "Providing the '$1' is mandatory!"
}

rev_tag_exists() {
	main_worktree=$1
	tag=$2
        git -C ${main_worktree} rev-parse -q --verify "refs/tags/${tag}" > /dev/null
}

rev_exists_local() {
	main_worktree=$1
	local_branch_name=$2
	git -C ${main_worktree} rev-parse -q --verify ${local_branch_name} > /dev/null
}

rev_exists_remote() {
	main_worktree=$1
	main_remote=$2
	local_branch_name=$3
	remote_branch_name="${main_remote}/${local_branch_name}"
	git -C ${main_worktree} rev-parse -q --verify ${remote_branch_name} > /dev/null
}

rev_exists() {
	main_worktree=$1
	main_remote=$2
	local_branch_name=$3
	remote_branch_name="${main_remote}/${local_branch_name}"
	rev_exists_local ${main_worktree} ${local_branch_name} ||
		rev_exists_remote ${main_worktree} ${main_remote} ${local_branch_name}
}

track=0
verbose=1
really_run=1
sayDo() {
	if [ -n "$verbose" ]; then echo -e ">> $@"; fi
	if [ -n "$really_run" ]; then eval "$@"; fi
}

while :; do
	case "$1" in
		-n)
			unset really_run
			shift;;
		-q)
			unset verbose
			shift;;
		-t)
			track=1
			shift;;
		-[h?])
			usage;;
		# Remember break stops the loop, not case!
		--)
			shift; break;;
		-*)
			usage_error "unrecognized option: $1";;
		*)
			break;;
	esac
done

if [ -z "$verbose" -a -z "$really_run" ]; then
	usage_error "-n and -q are incompatible"
fi
if [ "$track" = "1" -a -z "$really_run" ]; then
	usage_error "-n and -t are incompatible"
fi

cmd="$1"; shift || demand_arg command
case "$cmd" in
	add|remove|force_remove|clean|post_create) ;;
	*)
		echo -e '>>>> Usage error: Providing a valid ''$command'' is mandatory!\n'; usage;;
esac

topic="$1"; shift || demand_arg topic
# Turn / in topic into -
new_main_repo=$(realpath ${orig_main_repo}/..)/${main_repo_name}-${topic//\//-}

case "$cmd" in
	clean)
		sayDo make -C ${new_main_repo} clean
		exit $?
		;;
	post_create)
                # TODO update!
		sayDo cp ${orig_main_repo}/conf.mk ${new_main_repo}/ &&
		sayDo cp ${orig_main_repo}/NOVA/Makefile.conf ${new_main_repo}/NOVA/
		exit $?
		;;
esac

repo_relpath="$1"; shift || demand_arg repo_relpath
main_branch="$1"; shift || demand_arg branch

echo -e ">> WORKTREE ${cmd} ${repo_relpath}"

one_worktree() {
	cmd=$1
	repo_relpath=$2
	main_branch=$3
	main_worktree=${orig_main_repo}/${repo_relpath}
	new_worktree=${new_main_repo}/${repo_relpath}

	if rev_tag_exists ${main_worktree} ${main_branch}; then
		remote_tag=1
		main_branch_remote=${main_branch}
	else
		remote_tag=0
		main_branch_remote=${main_remote}/${main_branch}
	fi
	if rev_exists ${main_worktree} ${main_remote} ${topic}; then
		new_branch_name=${topic}
	else
		new_branch_name=$(prefix_branch_name ${topic})
	fi

	case "$cmd" in
		add)
                        # TODO: split into 1) branch creation and 2) worktree creation
                        # TODO: make both things idempotent.
			if rev_exists_remote ${main_worktree} ${main_remote} ${new_branch_name}; then
				sayDo git -C ${main_worktree} worktree add ${new_worktree} ${new_branch_name}
			elif rev_exists_local ${main_worktree} ${new_branch_name}; then
				sayDo git -C ${main_worktree} worktree add ${new_worktree} ${new_branch_name}
			else
				sayDo git -C ${main_worktree} worktree add --no-track -b ${new_branch_name} ${new_worktree} ${main_branch_remote}
			fi

			if [ "$track" = 1 ] && [ "$remote_tag" = 0 ]; then
				sayDo git -C ${main_worktree} branch --set-upstream-to ${main_branch_remote} ${new_branch_name}
			fi
			if [ -f "${new_worktree}/.gitmodules" ]; then
				sayDo git -C ${new_worktree} submodule update --init --recursive
			fi
			;;
		remove|force_remove)
			if [ "$cmd" = "remove" -a -f "${new_worktree}/.gitmodules" ]; then
				cmd="force_remove"
			fi

			case "$cmd" in
				remove)
					delete_opt=-d
					force_opt=
					;;
				force_remove)
					delete_opt=-D
					force_opt=--force
					;;
			esac

			# This code tries hard to keep going if some pieces have already been deleted;
			# so we ignore missing folders.
			if [ -d ${new_worktree} ]; then
				# Test if this is a worktree
				if [ -f ${new_worktree}/.git ]; then
					# But if the removal fails (because of stale files)
					# we must abort with extreme prejudice!
					sayDo git -C ${main_worktree} worktree remove ${force_opt} ${new_worktree}
				elif [ -d ${new_worktree}/.git ]; then
					if sayDo git -C ${new_worktree} clean -ndx | grep '.' ; then
						echo -e ">>>> Untracked files found in ${new_worktree}!!!\n"
						exit 1
					fi
					# Without the next step, `worktree prune` will not remove ${new_worktree}, and `branch -D` will then fail.
					sayDo rm -rf ${new_worktree}
				else
					cat <<-EOF
					>>>> ${new_worktree} is unexpectedly not a Git repo: ${new_worktree}/.git not found
					>>>> To complete worktree removal, inspect the situation,
					>>>> use 'rm -rf ${new_worktree}' to remove stale files if safe, and rerun this script.
					EOF
					exit 1
				fi
			fi

			# If the repo was removed by hand, make `git` update its metadata.
			sayDo git -C ${main_worktree} worktree prune

			# Skip deletion if branch was already deleted (to avoid a noisy error)
			if git -C ${main_worktree} show-ref --verify --quiet refs/heads/${new_branch_name}; then
				sayDo git -C ${main_worktree} branch $delete_opt ${new_branch_name} || true
			fi
			;;
	esac
}

one_worktree ${cmd} ${repo_relpath} ${main_branch}

# Demarcate output, useful when running in a loop.
if [ -n "$verbose" ]; then echo; fi

# Local Variables:
# indent-tabs-mode: t
# sh-basic-offset: 8
# End:
# vim: set sw=8 noet:
