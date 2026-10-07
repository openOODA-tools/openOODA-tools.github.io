#!/bin/sh
# oojq Web Uninstaller
set -eu
CANONICAL_URL="https://openooda-tools.github.io/oojq"
exec curl -fsSL "${CANONICAL_URL}/install.sh" | bash -s -- --uninstall "$@"
