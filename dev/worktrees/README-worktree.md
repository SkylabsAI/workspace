# Worktree support

Creates and removes parallel `skylabs-fm` worktrees without redownloading git history.
This uses [git worktree](https://git-scm.com/docs/git-worktree).

## Synopsis/quick reference

For instance (with `WORKTREE_TOPIC_PREFIX=paolo`):
```sh
# Add worktree ../skylabs-fm-dune for branch `paolo/dune`
./dev/worktrees/add.sh dune
# Check out existing branches `alice/topic` in worktree ../skylabs-fm-alice-topic
./dev/worktrees/add.sh alice/topic
# Remove worktree ../skylabs-fm-dune
./dev/worktrees/remove.sh dune
```

- Slashes (`/`) in the topic name become dashes (`-`) in directory names.
- `${WORKTREE_TOPIC_PREFIX}` (by default, your username) will be used as branch
name prefix.
To reduce redundancy, we omit prefix `${WORKTREE_TOPIC_PREFIX}` from worktree
directory names.
