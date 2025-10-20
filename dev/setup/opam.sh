#!/bin/bash

set -euf -o pipefail

if [[ -d ../../_opam ]]; then
  echo "A custom opam directory switch is already setup."
  echo "Found at: $(realpath ../../_opam)."
  exit 0
fi

if [[ -d ../_opam ]]; then
  echo "The opam directory switch is already setup."
  echo "Found at: $(realpath ../_opam)."
  exit 0
fi

if [[ -d _opam ]]; then
  echo "A local opam directory switch is already setup."
  echo "Note: it is not suitable for using worktrees."
  exit 0
fi

echo "Creating a new opam directory switch in $(realpath ../_opam)."
opam switch create --empty ..

echo "Adding the archive repository to the switch."
opam repo add --this-switch archive \
  git+https://github.com/ocaml/opam-repository-archive
