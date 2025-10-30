#!/bin/bash
#
# Copyright (c) 2025 SkyLabs AI, Inc.
#

set -euf -o pipefail

if [[ -d .venv ]]; then
  echo "The main Python virtual environment is already setup."
  echo "Found at: $(realpath .venv)"
  exit 0
fi

echo "Setting up a new Python virtual environment."
echo "Created in: $(realpath .venv)"
uv venv --quiet --python 3.11
