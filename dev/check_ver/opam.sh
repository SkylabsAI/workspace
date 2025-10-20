#!/bin/bash
#
# Copyright (c) 2024 BlueRock Security, Inc.
#
# This software is distributed under the terms of the BlueRock Open-Source
# License. See the LICENSE-BlueRock file at the repository root for details.
#

set -euf -o pipefail

MIN_VERSION="2.2.1"

if ! type opam 2> /dev/null > /dev/null; then
  echo -e "\033[0;31mCould not find opam."
  echo -e "We require at least version ${MIN_VERSION}."
  echo -e "See https://opam.ocaml.org/doc/Install.html for installation instructions.\033[0m"
  exit 1
fi

VER=$(opam --version)
if [[ "${MIN_VERSION}" != \
      "$(echo -e "${VER}\n${MIN_VERSION}" | sort -V | head -n1)" ]]; then
  echo -e "\033[0;31mYour version of opam (${VER}) is too old."
  echo -e "Version ${MIN_VERSION} at least is required."
  echo -e "See https://opam.ocaml.org/doc/Install.html for upgrade instructions.\033[0m"
else
  echo "Using opam version ${VER}."
fi
