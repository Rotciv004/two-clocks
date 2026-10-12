#!/usr/bin/env bash
set -euo pipefail
CABD_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$CABD_SCRIPT_DIR/phase3_runner.py" verify "$@"
