#!/usr/bin/env bash
# Creates two NEW isolated databases. Never resets an existing or main database.
set -Eeuo pipefail
CABD_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "$CABD_PROJECT_ROOT/scripts/phase2_runner.py" verify "$@"
