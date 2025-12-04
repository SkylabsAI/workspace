#!/bin/bash

set -e

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 clone_dir output_file.tar.gz"
  exit 1
fi

CLONE_DIR="$PWD/$1"
OUTPUT_FILE="$PWD/$2"

INITIAL_PWD="$PWD"

rm -rf "${CLONE_DIR}"

git clone git@github.com:SkyLabsAI/skylabs-fm.git "${CLONE_DIR}"

cd "${CLONE_DIR}"
git log --pretty=tformat:'%H' -n 1 > skylabs-fm_commit_hash.txt
cd ..

TAR=$(which gtar || which tar)
$TAR --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2000-01-01' \
  --exclude-vcs -zcf "${OUTPUT_FILE}" "$(basename ${CLONE_DIR})"

cd "${INITIAL_PWD}"
rm -rf "${CLONE_DIR}"
