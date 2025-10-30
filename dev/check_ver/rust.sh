#!/bin/bash
#
# Copyright (c) 2025 SkyLabs AI, Inc.
#

PROG="rustc"
URL="https://rust-lang.org/tools/install/"
MIN="1.85.0"
MAX="1.91.0"
RECOMMENDED="1.90.*"

print_ver() {
  VER="$(rustc --version | grep "rustc " | cut -d' ' -f2)"
  if ! [[ "${VER}" =~ ([^\.]*)\.([^\.]*)\.([^\.]*) ]]; then
    >&2 echo "Error: could not parse the output of 'rustc --version'."
    >&2 rustc --version
    exit 1
  fi
  echo "${VER}"
}

source "dev/check_ver/driver.inc.sh"
