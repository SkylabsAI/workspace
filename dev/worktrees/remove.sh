#!/bin/sh -xe

export topic=$1

[ -n "$WORKTREE_TOPIC_PREFIX" ] || WORKTREE_TOPIC_PREFIX=$USER
export WORKTREE_TOPIC_PREFIX

make revloop LOOP_COMMAND=dev/worktrees/helpers/repo-remove.sh -j
