#!/bin/bash
#
# Copyright (c) 2025 SkyLabs AI, Inc.
#

set -euf -o pipefail

if [[ -n $(uv run -- bash -c 'echo $VIRTUAL_ENV') ]]; then
  echo "The main Python virtual environment is already setup."
  echo "Found at: $(realpath .venv)"
  exit 0
fi

echo "Setting up a new Python virtual environment."
echo "Created in: .venv"
uv venv --quiet --python 3.11
