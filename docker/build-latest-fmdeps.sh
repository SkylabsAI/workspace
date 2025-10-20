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

git clone git@github.com:SkylabsAI/skylabs-fm.git "${CLONE_DIR}"
cd "${CLONE_DIR}"

make --no-print-directory -j20 fmdeps-clone
make --no-print-directory fmdeps-describe > fmdeps_commit_hashes.txt

ARCHIVE_DIR="$(basename "${CLONE_DIR}")"
mkdir "${ARCHIVE_DIR}"
mv fmdeps "${ARCHIVE_DIR}"/
mv fmdeps_commit_hashes.txt "${ARCHIVE_DIR}"/
mv dune-workspace "${ARCHIVE_DIR}"/

TAR=$(which gtar || which tar)
$TAR --sort=name --owner=root:0 --group=root:0 --mtime='UTC 2000-01-01' \
  --exclude-vcs -zcf "${OUTPUT_FILE}" "${ARCHIVE_DIR}"

cd "${INITIAL_PWD}"
rm -rf "${CLONE_DIR}"
