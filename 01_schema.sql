-- Two Clocks / Part A. DESTRUCTIVE object recreation in the client-selected database.
-- Never run on an existing populated main database. DDL commits implicitly.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP VIEW IF EXISTS v_integrity_violations;

DROP TABLE IF EXISTS tx_event_tag;
DROP TABLE IF EXISTS head_coach_role_version;
DROP TABLE IF EXISTS contract_version;
DROP TABLE IF EXISTS club_version;
DROP TABLE IF EXISTS query_params;
DROP TABLE IF EXISTS head_coach_role;
DROP TABLE IF EXISTS contract;
DROP TABLE IF EXISTS season;
DROP TABLE IF EXISTS club;
DROP TABLE IF EXISTS coach;
DROP TABLE IF EXISTS player;
DROP TABLE IF EXISTS tx_registry;
DROP FUNCTION IF EXISTS fn_effective_time;
CREATE TABLE player (
  player_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  player_code VARCHAR(32) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  birth_date DATE NOT NULL,
  CONSTRAINT pk_player PRIMARY KEY (player_id),
  CONSTRAINT uq_player_code UNIQUE (player_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE coach (
  coach_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  coach_code VARCHAR(32) NOT NULL,
  full_name VARCHAR(120) NOT NULL,
  birth_date DATE NOT NULL,
  CONSTRAINT pk_coach PRIMARY KEY (coach_id),
  CONSTRAINT uq_coach_code UNIQUE (coach_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE club (
  club_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_code VARCHAR(32) NOT NULL,
  CONSTRAINT pk_club PRIMARY KEY (club_id),
  CONSTRAINT uq_club_code UNIQUE (club_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE season (
  season_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  season_name VARCHAR(32) NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  CONSTRAINT pk_season PRIMARY KEY (season_id),
  CONSTRAINT uq_season_name UNIQUE (season_name),
  CONSTRAINT ck_season_period CHECK (period_start < period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE contract (
  contract_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  player_id BIGINT UNSIGNED NOT NULL,
  club_id BIGINT UNSIGNED NOT NULL,
  CONSTRAINT pk_contract PRIMARY KEY (contract_id),
  CONSTRAINT uq_contract_pair UNIQUE (player_id, club_id),
  INDEX ix_contract_club (club_id),
  CONSTRAINT fk_contract_player_id FOREIGN KEY (player_id) REFERENCES player (player_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_contract_club_id FOREIGN KEY (club_id) REFERENCES club (club_id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE head_coach_role (
  role_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  CONSTRAINT pk_head_coach_role PRIMARY KEY (role_id),
  CONSTRAINT uq_head_coach_role_club UNIQUE (club_id),
  CONSTRAINT fk_head_coach_role_club_id FOREIGN KEY (club_id) REFERENCES club (club_id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tx_registry (
  tx_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tx_time DATETIME(6) NOT NULL,
  author VARCHAR(128) NOT NULL,
  reason TEXT NOT NULL,
  CONSTRAINT pk_tx_registry PRIMARY KEY (tx_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tx_event_tag (
  tx_id BIGINT UNSIGNED NOT NULL,
  event_code CHAR(2) NOT NULL,
  CONSTRAINT pk_tx_event_tag PRIMARY KEY (tx_id, event_code),
  CONSTRAINT fk_tx_event_tag_tx_id FOREIGN KEY (tx_id) REFERENCES tx_registry (tx_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT ck_tx_event_tag_code CHECK (event_code IN ('E1','E2','E3','E4','E5','E6','E7','E8','E9'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE club_version (
  version_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  club_id BIGINT UNSIGNED NOT NULL,
  club_name VARCHAR(120) NOT NULL,
  budget_eur DECIMAL(14,2) NOT NULL,
  valid_from DATE NOT NULL,
  valid_to DATE NOT NULL DEFAULT '9999-12-31',
  tx_from DATETIME(6) NOT NULL,
  tx_to DATETIME(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
  tx_id BIGINT UNSIGNED NOT NULL,
  CONSTRAINT pk_club_version PRIMARY KEY (version_id),
  INDEX ix_club_version_asof (club_id, tx_to, valid_from),
  INDEX ix_club_version_tx (tx_id),
  CONSTRAINT fk_club_version_club_id FOREIGN KEY (club_id) REFERENCES club (club_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_club_version_tx_id FOREIGN KEY (tx_id) REFERENCES tx_registry (tx_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT ck_club_version_valid CHECK (valid_from < valid_to),
  CONSTRAINT ck_club_version_tx CHECK (tx_from < tx_to),
  CONSTRAINT ck_club_version_budget CHECK (budget_eur >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE contract_version (
  version_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  contract_id BIGINT UNSIGNED NOT NULL,
  agreement_kind VARCHAR(9) NOT NULL,
  salary_eur DECIMAL(12,2) NOT NULL,
  valid_from DATE NOT NULL,
  valid_to DATE NOT NULL DEFAULT '9999-12-31',
  tx_from DATETIME(6) NOT NULL,
  tx_to DATETIME(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
  tx_id BIGINT UNSIGNED NOT NULL,
  CONSTRAINT pk_contract_version PRIMARY KEY (version_id),
  INDEX ix_contract_version_asof (contract_id, tx_to, valid_from),
  INDEX ix_contract_version_tx (tx_id),
  CONSTRAINT fk_contract_version_contract_id FOREIGN KEY (contract_id) REFERENCES contract (contract_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_contract_version_tx_id FOREIGN KEY (tx_id) REFERENCES tx_registry (tx_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT ck_contract_version_valid CHECK (valid_from < valid_to),
  CONSTRAINT ck_contract_version_tx CHECK (tx_from < tx_to),
  CONSTRAINT ck_contract_version_kind CHECK (agreement_kind IN ('PERMANENT','LOAN')),
  CONSTRAINT ck_contract_version_salary CHECK (salary_eur >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE head_coach_role_version (
  version_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id BIGINT UNSIGNED NOT NULL,
  coach_id BIGINT UNSIGNED NOT NULL,
  valid_from DATE NOT NULL,
  valid_to DATE NOT NULL DEFAULT '9999-12-31',
  tx_from DATETIME(6) NOT NULL,
  tx_to DATETIME(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
  tx_id BIGINT UNSIGNED NOT NULL,
  CONSTRAINT pk_head_coach_role_version PRIMARY KEY (version_id),
  INDEX ix_head_coach_role_version_asof (role_id, tx_to, valid_from),
  INDEX ix_head_coach_role_version_tx (tx_id),
  CONSTRAINT fk_head_coach_role_version_role_id FOREIGN KEY (role_id) REFERENCES head_coach_role (role_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_head_coach_role_version_tx_id FOREIGN KEY (tx_id) REFERENCES tx_registry (tx_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT ck_head_coach_role_version_valid CHECK (valid_from < valid_to),
  CONSTRAINT ck_head_coach_role_version_tx CHECK (tx_from < tx_to),
  INDEX ix_head_coach_role_version_coach (coach_id),
  CONSTRAINT fk_head_coach_role_version_coach_id FOREIGN KEY (coach_id) REFERENCES coach (coach_id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE query_params (
  params_id TINYINT UNSIGNED NOT NULL,
  valid_at DATE NOT NULL,
  known_at DATETIME(6) NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  subject_id BIGINT UNSIGNED NOT NULL,
  CONSTRAINT pk_query_params PRIMARY KEY (params_id),
  CONSTRAINT ck_query_params_singleton CHECK (params_id = 1),
  CONSTRAINT ck_query_params_period CHECK (period_start < period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO query_params VALUES (1,'2026-03-02','2026-03-16 12:00:00.000000','2025-07-01','2026-07-01',1);

DELIMITER $$
-- @sim_now is NULL/unset or a canonical UTC datetime with 0..6 fractional digits.
CREATE FUNCTION fn_effective_time() RETURNS DATETIME(6)
NOT DETERMINISTIC NO SQL SQL SECURITY INVOKER
BEGIN
  DECLARE v_text VARCHAR(128);
  DECLARE v_time DATETIME(6);
  DECLARE v_day INT;
  DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOCK: invalid or future @sim_now';
  IF @sim_now IS NULL THEN RETURN UTC_TIMESTAMP(6); END IF;
  SET v_text = CAST(@sim_now AS CHAR);
  IF v_text NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]{1,6})?$'
  THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOCK'; END IF;
  SET v_time = CAST(v_text AS DATETIME(6));
  SET v_day = CAST(SUBSTRING(v_text,9,2) AS UNSIGNED);
  IF v_time IS NULL OR YEAR(v_time) < 1000 OR MONTH(v_time) = 0
     OR v_day < 1 OR LAST_DAY(v_time) IS NULL OR v_day > DAY(LAST_DAY(v_time))
     OR v_time > UTC_TIMESTAMP(6)
  THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOCK'; END IF;
  RETURN v_time;
END$$
CREATE TRIGGER tr_tx_registry_insert BEFORE INSERT ON tx_registry FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 SET v_now = fn_effective_time();
 IF NEW.tx_time > v_now OR NEW.tx_time > UTC_TIMESTAMP(6)
    OR (@sim_now IS NOT NULL AND NEW.tx_time <> v_now) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_REGISTRY_TIME: expected effective UTC time';
 END IF;
END$$

CREATE TRIGGER tr_tx_registry_update BEFORE UPDATE ON tx_registry FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_METADATA: immutable tx_registry'$$
CREATE TRIGGER tr_tx_registry_delete BEFORE DELETE ON tx_registry FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_METADATA: immutable tx_registry'$$
CREATE TRIGGER tr_tx_event_tag_update BEFORE UPDATE ON tx_event_tag FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_METADATA: immutable tx_event_tag'$$
CREATE TRIGGER tr_tx_event_tag_delete BEFORE DELETE ON tx_event_tag FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_METADATA: immutable tx_event_tag'$$
CREATE TRIGGER tr_contract_identity BEFORE UPDATE ON contract FOR EACH ROW
BEGIN
 IF NOT (NEW.contract_id <=> OLD.contract_id) OR NOT (NEW.player_id <=> OLD.player_id) OR NOT (NEW.club_id <=> OLD.club_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_ANCHOR: stable identity'; END IF;
END$$
CREATE TRIGGER tr_head_coach_role_identity BEFORE UPDATE ON head_coach_role FOR EACH ROW
BEGIN
 IF NOT (NEW.role_id <=> OLD.role_id) OR NOT (NEW.club_id <=> OLD.club_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_ANCHOR: stable identity'; END IF;
END$$
CREATE TRIGGER tr_club_version_insert BEFORE INSERT ON club_version FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 DECLARE v_registered DATETIME(6);
 SET v_now = fn_effective_time();
 SET v_registered = (SELECT tx_time FROM tx_registry WHERE tx_id = NEW.tx_id);
 IF v_registered IS NULL OR NEW.tx_from <> v_registered THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_TIME: tx_from must match registry'; END IF;
 IF NEW.tx_to <> '9999-12-31 23:59:59.999999' THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_OPEN: new belief must be open'; END IF;
 IF NEW.tx_from > v_now OR NEW.tx_from > UTC_TIMESTAMP(6)
    OR (@sim_now IS NOT NULL AND NEW.tx_from <> v_now) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_FUTURE: invalid effective time'; END IF;
END$$
CREATE TRIGGER tr_club_version_update BEFORE UPDATE ON club_version FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 DECLARE v_close DATETIME(6);
 IF OLD.tx_to <> '9999-12-31 23:59:59.999999' THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSED: history is immutable'; END IF;
 IF NOT (NEW.version_id <=> OLD.version_id) OR
    NOT (NEW.club_id <=> OLD.club_id) OR
    NOT (BINARY NEW.club_name <=> BINARY OLD.club_name) OR
    NOT (NEW.budget_eur <=> OLD.budget_eur) OR
    NOT (NEW.valid_from <=> OLD.valid_from) OR
    NOT (NEW.valid_to <=> OLD.valid_to) OR
    NOT (NEW.tx_from <=> OLD.tx_from) OR
    NOT (NEW.tx_id <=> OLD.tx_id) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_COLUMNS: only tx_to may change'; END IF;
 SET v_now = fn_effective_time();
 SET v_close = (SELECT tx_time FROM tx_registry WHERE tx_id = @write_tx_id);
 IF NEW.tx_to = '9999-12-31 23:59:59.999999' OR NEW.tx_to <= OLD.tx_from THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_ORDER: closure must follow opening'; END IF;
 IF NEW.tx_to > v_now OR NEW.tx_to > UTC_TIMESTAMP(6) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_FUTURE: closure beyond effective time'; END IF;
 IF v_close IS NULL OR NEW.tx_to <> v_close
    OR (@sim_now IS NOT NULL AND NEW.tx_to <> v_now) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_REGISTRY: use @write_tx_id and its time'; END IF;
END$$
CREATE TRIGGER tr_club_version_delete BEFORE DELETE ON club_version FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_DELETE: physical deletion forbidden'$$
CREATE TRIGGER tr_contract_version_insert BEFORE INSERT ON contract_version FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 DECLARE v_registered DATETIME(6);
 SET v_now = fn_effective_time();
 SET v_registered = (SELECT tx_time FROM tx_registry WHERE tx_id = NEW.tx_id);
 IF v_registered IS NULL OR NEW.tx_from <> v_registered THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_TIME: tx_from must match registry'; END IF;
 IF NEW.tx_to <> '9999-12-31 23:59:59.999999' THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_OPEN: new belief must be open'; END IF;
 IF NEW.tx_from > v_now OR NEW.tx_from > UTC_TIMESTAMP(6)
    OR (@sim_now IS NOT NULL AND NEW.tx_from <> v_now) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_FUTURE: invalid effective time'; END IF;
END$$
CREATE TRIGGER tr_contract_version_update BEFORE UPDATE ON contract_version FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 DECLARE v_close DATETIME(6);
 IF OLD.tx_to <> '9999-12-31 23:59:59.999999' THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSED: history is immutable'; END IF;
 IF NOT (NEW.version_id <=> OLD.version_id) OR
    NOT (NEW.contract_id <=> OLD.contract_id) OR
    NOT (BINARY NEW.agreement_kind <=> BINARY OLD.agreement_kind) OR
    NOT (NEW.salary_eur <=> OLD.salary_eur) OR
    NOT (NEW.valid_from <=> OLD.valid_from) OR
    NOT (NEW.valid_to <=> OLD.valid_to) OR
    NOT (NEW.tx_from <=> OLD.tx_from) OR
    NOT (NEW.tx_id <=> OLD.tx_id) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_COLUMNS: only tx_to may change'; END IF;
 SET v_now = fn_effective_time();
 SET v_close = (SELECT tx_time FROM tx_registry WHERE tx_id = @write_tx_id);
 IF NEW.tx_to = '9999-12-31 23:59:59.999999' OR NEW.tx_to <= OLD.tx_from THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_ORDER: closure must follow opening'; END IF;
 IF NEW.tx_to > v_now OR NEW.tx_to > UTC_TIMESTAMP(6) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_FUTURE: closure beyond effective time'; END IF;
 IF v_close IS NULL OR NEW.tx_to <> v_close
    OR (@sim_now IS NOT NULL AND NEW.tx_to <> v_now) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_REGISTRY: use @write_tx_id and its time'; END IF;
END$$
CREATE TRIGGER tr_contract_version_delete BEFORE DELETE ON contract_version FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_DELETE: physical deletion forbidden'$$
CREATE TRIGGER tr_head_coach_role_version_insert BEFORE INSERT ON head_coach_role_version FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 DECLARE v_registered DATETIME(6);
 SET v_now = fn_effective_time();
 SET v_registered = (SELECT tx_time FROM tx_registry WHERE tx_id = NEW.tx_id);
 IF v_registered IS NULL OR NEW.tx_from <> v_registered THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_TIME: tx_from must match registry'; END IF;
 IF NEW.tx_to <> '9999-12-31 23:59:59.999999' THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_OPEN: new belief must be open'; END IF;
 IF NEW.tx_from > v_now OR NEW.tx_from > UTC_TIMESTAMP(6)
    OR (@sim_now IS NOT NULL AND NEW.tx_from <> v_now) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_INSERT_FUTURE: invalid effective time'; END IF;
END$$
CREATE TRIGGER tr_head_coach_role_version_update BEFORE UPDATE ON head_coach_role_version FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 DECLARE v_close DATETIME(6);
 IF OLD.tx_to <> '9999-12-31 23:59:59.999999' THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSED: history is immutable'; END IF;
 IF NOT (NEW.version_id <=> OLD.version_id) OR
    NOT (NEW.role_id <=> OLD.role_id) OR
    NOT (NEW.coach_id <=> OLD.coach_id) OR
    NOT (NEW.valid_from <=> OLD.valid_from) OR
    NOT (NEW.valid_to <=> OLD.valid_to) OR
    NOT (NEW.tx_from <=> OLD.tx_from) OR
    NOT (NEW.tx_id <=> OLD.tx_id) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_COLUMNS: only tx_to may change'; END IF;
 SET v_now = fn_effective_time();
 SET v_close = (SELECT tx_time FROM tx_registry WHERE tx_id = @write_tx_id);
 IF NEW.tx_to = '9999-12-31 23:59:59.999999' OR NEW.tx_to <= OLD.tx_from THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_ORDER: closure must follow opening'; END IF;
 IF NEW.tx_to > v_now OR NEW.tx_to > UTC_TIMESTAMP(6) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_FUTURE: closure beyond effective time'; END IF;
 IF v_close IS NULL OR NEW.tx_to <> v_close
    OR (@sim_now IS NOT NULL AND NEW.tx_to <> v_now) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSE_REGISTRY: use @write_tx_id and its time'; END IF;
END$$
CREATE TRIGGER tr_head_coach_role_version_delete BEFORE DELETE ON head_coach_role_version FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_DELETE: physical deletion forbidden'$$
DELIMITER ;

-- Running MAX, not LAG(end): nested/overlapping parents must not create false gaps.
CREATE SQL SECURITY INVOKER VIEW v_integrity_violations AS
WITH parent_scan AS (
 SELECT club_id, version_id, valid_from, valid_to,
 MAX(valid_to) OVER (PARTITION BY club_id ORDER BY valid_from, version_id
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_end
 FROM club_version WHERE tx_to = '9999-12-31 23:59:59.999999'
), marked AS (
 SELECT *, CASE WHEN prior_end IS NULL OR prior_end < valid_from THEN 1 ELSE 0 END AS new_island
 FROM parent_scan
), numbered AS (
 SELECT *, SUM(new_island) OVER (PARTITION BY club_id ORDER BY valid_from, version_id
                                ROWS UNBOUNDED PRECEDING) AS island_id
 FROM marked
), parent_union AS (
 SELECT club_id, island_id, MIN(valid_from) AS valid_from, MAX(valid_to) AS valid_to
 FROM numbered GROUP BY club_id, island_id
)

SELECT 'I1' AS invariant_code, 'club_version' AS source_table,
 a.club_id AS business_key, a.version_id, b.version_id AS conflicting_version_id,
 CONCAT('club_id=', a.club_id, ': overlapping current valid periods') AS details
 FROM club_version a JOIN club_version b ON a.club_id = b.club_id AND a.version_id < b.version_id
 AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to
 WHERE a.tx_to = '9999-12-31 23:59:59.999999' AND b.tx_to = '9999-12-31 23:59:59.999999'
UNION ALL
SELECT 'I1' AS invariant_code, 'contract_version' AS source_table,
 a.contract_id AS business_key, a.version_id, b.version_id AS conflicting_version_id,
 CONCAT('contract_id=', a.contract_id, ': overlapping current valid periods') AS details
 FROM contract_version a JOIN contract_version b ON a.contract_id = b.contract_id AND a.version_id < b.version_id
 AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to
 WHERE a.tx_to = '9999-12-31 23:59:59.999999' AND b.tx_to = '9999-12-31 23:59:59.999999'
UNION ALL
SELECT 'I1' AS invariant_code, 'head_coach_role_version' AS source_table,
 a.role_id AS business_key, a.version_id, b.version_id AS conflicting_version_id,
 CONCAT('role_id=', a.role_id, ': overlapping current valid periods') AS details
 FROM head_coach_role_version a JOIN head_coach_role_version b ON a.role_id = b.role_id AND a.version_id < b.version_id
 AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to
 WHERE a.tx_to = '9999-12-31 23:59:59.999999' AND b.tx_to = '9999-12-31 23:59:59.999999'
UNION ALL
SELECT 'I2', 'contract_version', v.contract_id, v.version_id, CAST(NULL AS UNSIGNED),
 CONCAT('contract_id=',v.contract_id,': club_id=', a.club_id, ' does not cover [',v.valid_from,',',v.valid_to,')')
 FROM contract_version v JOIN contract a ON a.contract_id = v.contract_id
 WHERE v.tx_to = '9999-12-31 23:59:59.999999'
 AND NOT EXISTS (SELECT 1 FROM parent_union p WHERE p.club_id = a.club_id
                 AND p.valid_from <= v.valid_from AND v.valid_to <= p.valid_to)
UNION ALL
SELECT 'I2', 'head_coach_role_version', v.role_id, v.version_id, CAST(NULL AS UNSIGNED),
 CONCAT('role_id=',v.role_id,': club_id=', a.club_id, ' does not cover [',v.valid_from,',',v.valid_to,')')
 FROM head_coach_role_version v JOIN head_coach_role a ON a.role_id = v.role_id
 WHERE v.tx_to = '9999-12-31 23:59:59.999999'
 AND NOT EXISTS (SELECT 1 FROM parent_union p WHERE p.club_id = a.club_id
                 AND p.valid_from <= v.valid_from AND v.valid_to <= p.valid_to)
UNION ALL
SELECT 'I3', 'head_coach_role_version', ra.club_id, a.version_id, b.version_id,
 CONCAT('club_id=',ra.club_id,': multiple current head coach assignments')
 FROM head_coach_role_version a JOIN head_coach_role ra ON ra.role_id = a.role_id
 JOIN head_coach_role rb ON rb.club_id = ra.club_id
 JOIN head_coach_role_version b ON b.role_id = rb.role_id AND a.version_id < b.version_id
 AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to
 WHERE a.tx_to = '9999-12-31 23:59:59.999999' AND b.tx_to = '9999-12-31 23:59:59.999999';
