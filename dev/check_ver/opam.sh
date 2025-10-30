#!/bin/bash
#
# Copyright (c) 2025 SkyLabs AI, Inc.
#

PROG="opam"
URL="https://opam.ocaml.org/doc/Install.html"
MIN="2.2.1"

print_ver() {
  opam --version
}

source "dev/check_ver/driver.inc.sh"
