#!/bin/bash
#
# Copyright (c) 2025 SkyLabs AI, Inc.
#

PROG="clang"
URL="https://apt.llvm.org"
MIN="18.0.0"
MAX="21.0.0"
RECOMMENDED="19.*.*"

print_ver() {
  VER="$(clang --version | grep "clang version" | cut -d' ' -f3)"
  if ! [[ "${VER}" =~ ([^\.]*)\.([^\.]*)\.([^\.]*) ]]; then
    >&2 echo "Error: could not parse the output of 'clang --version'."
    >&2 clang --version
    exit 1
  fi
  echo "${VER}"
}

extra_checks() {
  if ! echo "int main(){}" | clang++ -xc++ -stdlib=libc++ - 2>/dev/null; then
    echo -e "\033[0;31mError: libc++ does not seem to be installed.\033[0m"
    exit 1
  else
    rm a.out
  fi
}

source "dev/check_ver/driver.inc.sh"
