#!/bin/bash
#
# Copyright (c) 2024 BlueRock Security, Inc.
#
# This software is distributed under the terms of the BlueRock Open-Source
# License. See the LICENSE-BlueRock file at the repository root for details.
#

set -euf -o pipefail

MIN_MAJOR_VER="18"
MAX_MAJOR_VER="20"
RECOMMENDED_VER="19"

if ! type clang 2> /dev/null > /dev/null; then
  echo -e "\033[0;31mCould not find clang."
  echo -e "We recommend version ${RECOMMENDED_VER} (see https://apt.llvm.org).\033[0m"
  exit 1
fi

VER="$(clang --version | \
               grep "clang version" | \
               sed -r 's/^.*clang version ([0-9.]+).*$/\1/' | \
               cut -d' ' -f3)"
MAJOR_VER="$(echo ${VER} | cut -d'.' -f1)"

if seq ${MIN_MAJOR_VER} ${MAX_MAJOR_VER} | grep -q "${MAJOR_VER}"; then
  if ! echo "int main(){}" | clang++ -xc++ -stdlib=libc++ - 2>/dev/null; then
    echo -e "\033[0;31mError: it seems you don't have libc++ installed."
    exit 1
  else
    rm a.out
  fi

  echo "Using clang version ${VER}."
else
  echo -e "\033[0;31mError: clang version ${VER} is not supported."
  echo -e "A major version between ${MIN_MAJOR_VER} and ${MAX_MAJOR_VER} is expected.\033[0m"
  exit 1
fi
