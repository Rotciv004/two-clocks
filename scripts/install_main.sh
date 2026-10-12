#!/usr/bin/env bash
# Safe first installation only. Refuses ALL existing objects, including our own.
set -Eeuo pipefail
CABD_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CABD_CLIENT=(mariadb "$@" --default-character-set=utf8mb4 --batch)
CABD_EXISTING="$("${CABD_CLIENT[@]}" --skip-column-names -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='two_clocks_cabd';")"
CABD_ROUTINES="$("${CABD_CLIENT[@]}" --skip-column-names -e "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='two_clocks_cabd';")"
if [[ "$CABD_EXISTING" != 0 || "$CABD_ROUTINES" != 0 ]]; then
  echo 'STOP: main database already has objects; no reset is authorized. Inspect and back up before a reviewed migration.' >&2
  exit 2
fi
"${CABD_CLIENT[@]}" < "$CABD_PROJECT_ROOT/00_create_database.sql"
CABD_SELECTED="$("${CABD_CLIENT[@]}" --skip-column-names --database=two_clocks_cabd -e 'SELECT DATABASE();')"
[[ "$CABD_SELECTED" == two_clocks_cabd ]] || exit 3
"${CABD_CLIENT[@]}" --database=two_clocks_cabd < "$CABD_PROJECT_ROOT/01_schema.sql"
"${CABD_CLIENT[@]}" --database=two_clocks_cabd -e "SELECT VERSION(),CURRENT_USER(),DATABASE(),@@session.time_zone,@@session.sql_mode; SHOW FULL TABLES; SELECT * FROM query_params; SELECT * FROM v_integrity_violations; SELECT 'player' AS name, COUNT(*) AS rows_in_main FROM player UNION ALL SELECT 'coach',COUNT(*) FROM coach UNION ALL SELECT 'club',COUNT(*) FROM club UNION ALL SELECT 'season',COUNT(*) FROM season UNION ALL SELECT 'contract',COUNT(*) FROM contract UNION ALL SELECT 'head_coach_role',COUNT(*) FROM head_coach_role UNION ALL SELECT 'club_version',COUNT(*) FROM club_version UNION ALL SELECT 'contract_version',COUNT(*) FROM contract_version UNION ALL SELECT 'head_coach_role_version',COUNT(*) FROM head_coach_role_version UNION ALL SELECT 'tx_registry',COUNT(*) FROM tx_registry UNION ALL SELECT 'tx_event_tag',COUNT(*) FROM tx_event_tag;" > "$CABD_PROJECT_ROOT/verification/main_structure.log"
mariadb-dump "$@" --default-character-set=utf8mb4 --no-data --routines --triggers --skip-comments two_clocks_cabd > "$CABD_PROJECT_ROOT/exports/schema_only.sql"
echo 'PASS: initial main installation and real structural dump complete.'

CABD_OWNER="${PKEXEC_UID:-${SUDO_UID:-}}"
if [[ $EUID == 0 && "$CABD_OWNER" =~ ^[0-9]+$ ]]; then
  chown -- "$CABD_OWNER" "$CABD_PROJECT_ROOT/verification/main_structure.log" "$CABD_PROJECT_ROOT/exports/schema_only.sql"
fi
