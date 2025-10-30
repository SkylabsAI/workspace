#!/bin/bash
#
# Copyright (c) 2025 SkyLabs AI, Inc.
#

PROG="uv"
URL="https://github.com/astral-sh/uv/blob/main/README.md"
MIN="0.9.0"
MAX="0.10.0"

print_ver() {
  uv self version --short | cut -d' ' -f1
}

source "dev/check_ver/driver.inc.sh"
