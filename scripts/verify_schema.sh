#!/usr/bin/env bash
# Every invocation creates a NEW database; existing databases are never dropped.
set -Eeuo pipefail
CABD_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CABD_VERIFY_SUFFIX="$(date -u +%Y%m%d_%H%M%S)_${BASHPID}_${RANDOM}"
CABD_VERIFY_DB="two_clocks_cabd_verify_${CABD_VERIFY_SUFFIX}"
CABD_LOG_DIR="$CABD_PROJECT_ROOT/verification/$CABD_VERIFY_DB"
mkdir -p "$CABD_LOG_DIR"
# Pass existing client connection options, never a password value on the command line.
CABD_CLIENT=(mariadb "$@" --default-character-set=utf8mb4 --batch --show-warnings)
exec > >(tee "$CABD_LOG_DIR/run.log") 2>&1
cabd_finish() {
  local status=$?
  if (( status != 0 )); then printf 'FAIL exit=%s database=%s\n' "$status" "$CABD_VERIFY_DB"; fi
  local cabd_owner="${PKEXEC_UID:-${SUDO_UID:-}}"
  if [[ $EUID == 0 && "$cabd_owner" =~ ^[0-9]+$ ]]; then
    chown -R -- "$cabd_owner" "$CABD_LOG_DIR"
    if [[ -f "$CABD_PROJECT_ROOT/verification/latest_success.txt" ]]; then
      chown -- "$cabd_owner" "$CABD_PROJECT_ROOT/verification/latest_success.txt"
    fi
  fi
  return "$status"
}
trap cabd_finish EXIT
printf 'UTC start: %s\nDatabase: %s\n' "$(date -u --iso-8601=seconds)" "$CABD_VERIFY_DB"
"${CABD_CLIENT[@]}" -e 'SELECT VERSION(), CURRENT_USER(), DATABASE(), @@session.time_zone, @@session.sql_mode;'
"${CABD_CLIENT[@]}" -e "CREATE DATABASE \`$CABD_VERIFY_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
printf '%s\n' "$CABD_VERIFY_DB" > "$CABD_LOG_DIR/database.txt"
for CABD_PASS in 1 2; do
  CABD_SELECTED="$("${CABD_CLIENT[@]}" --skip-column-names --database="$CABD_VERIFY_DB" -e 'SELECT DATABASE();')"
  [[ "$CABD_SELECTED" == "$CABD_VERIFY_DB" ]] || { echo 'Wrong database selected'; exit 1; }
  printf 'Schema recreation pass %s (test database only)\n' "$CABD_PASS"
  "${CABD_CLIENT[@]}" --database="$CABD_VERIFY_DB" < "$CABD_PROJECT_ROOT/01_schema.sql" > "$CABD_LOG_DIR/schema_pass_${CABD_PASS}.log" 2>&1 || { cat "$CABD_LOG_DIR/schema_pass_${CABD_PASS}.log"; exit 1; }
done
for CABD_TEST in 01_schema_smoke 02_write_examples; do
  printf 'Running %s\n' "$CABD_TEST"
  "${CABD_CLIENT[@]}" --database="$CABD_VERIFY_DB" < "$CABD_PROJECT_ROOT/tests/$CABD_TEST.sql" > "$CABD_LOG_DIR/$CABD_TEST.log" 2>&1 || { cat "$CABD_LOG_DIR/$CABD_TEST.log"; exit 1; }
  tail -n 3 "$CABD_LOG_DIR/$CABD_TEST.log"
  printf 'Full log: %s\n' "$CABD_LOG_DIR/$CABD_TEST.log"
done
"${CABD_CLIENT[@]}" --database="$CABD_VERIFY_DB" -e 'SHOW FULL TABLES; SHOW TRIGGERS; SHOW CREATE TABLE club_version; SHOW CREATE TABLE contract_version; SHOW CREATE TABLE head_coach_role_version; SELECT * FROM query_params; SELECT * FROM v_integrity_violations;' > "$CABD_LOG_DIR/structure.log"
printf 'PASS: two schema runs, smoke tests and write examples. Test database retained: %s\n' "$CABD_VERIFY_DB"
printf '%s\n' "$CABD_LOG_DIR" > "$CABD_PROJECT_ROOT/verification/latest_success.txt"
