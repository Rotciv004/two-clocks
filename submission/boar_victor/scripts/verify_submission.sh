#!/usr/bin/env bash
# Replay numai într-o bază nouă; fișierele sunt cele din pachetul selectat.
set -Eeuo pipefail
CABD_VERIFY_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$CABD_VERIFY_SCRIPT_DIR/verify_submission.py" "$@"
