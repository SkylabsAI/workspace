Dependency Checking Infrastructure
==================================

Template
--------

```bash
#!/bin/bash

PROG="prog" # Program name.
URL="https://prog.html/install/" # Installation instructions.
MIN="42.0.1" # Minimum supported version (included).
MAX="50.0.0" # First version that is not supported (optional).
RECOMMENDED="..." # Recommended version (optional).

# Function that prints the version.
print_ver() {
  ...
}

# Function that performs extra checks (optional)
extra_checks() {
  ...
}

source "dev/check_ver/driver.inc.sh"
```
