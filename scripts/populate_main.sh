#!/usr/bin/env bash
# Requires successful verification of these exact files. Never runs 01 on main.
set -Eeuo pipefail
CABD_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "$CABD_PROJECT_ROOT/scripts/phase2_runner.py" main "$@"
