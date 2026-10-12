from pathlib import Path
root=Path(__file__).resolve().parents[1]
S=[]
def add(s): S.append(s)
add("""-- Two Clocks / Part A. DESTRUCTIVE object recreation in the client-selected database.
-- Never run on an existing populated main database. DDL commits implicitly.
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP VIEW IF EXISTS v_integrity_violations;
""")
for t in ['tx_event_tag','head_coach_role_version','contract_version','club_version','query_params','head_coach_role','contract','season','club','coach','player','tx_registry']: add(f'DROP TABLE IF EXISTS {t};')
add('DROP FUNCTION IF EXISTS fn_effective_time;')
def table(t,cols,cons=[]):
 add('CREATE TABLE '+t+' (\n  '+',\n  '.join(cols+cons)+'\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;\n')
def pk(t,c): return f'CONSTRAINT pk_{t} PRIMARY KEY ({c})'
def fk(t,c,p,pc):return f'CONSTRAINT fk_{t}_{c} FOREIGN KEY ({c}) REFERENCES {p} ({pc}) ON DELETE RESTRICT ON UPDATE RESTRICT'
def id(c):return f'{c} BIGINT UNSIGNED NOT NULL AUTO_INCREMENT'
for t in ['player','coach']:
 table(t,[id(t+'_id'),f'{t}_code VARCHAR(32) NOT NULL','full_name VARCHAR(120) NOT NULL','birth_date DATE NOT NULL'],[pk(t,t+'_id'),f'CONSTRAINT uq_{t}_code UNIQUE ({t}_code)'])
table('club',[id('club_id'),'club_code VARCHAR(32) NOT NULL'],[pk('club','club_id'),'CONSTRAINT uq_club_code UNIQUE (club_code)'])
table('season',[id('season_id'),'season_name VARCHAR(32) NOT NULL','period_start DATE NOT NULL','period_end DATE NOT NULL'],[pk('season','season_id'),'CONSTRAINT uq_season_name UNIQUE (season_name)','CONSTRAINT ck_season_period CHECK (period_start < period_end)'])
table('contract',[id('contract_id'),'player_id BIGINT UNSIGNED NOT NULL','club_id BIGINT UNSIGNED NOT NULL'],[pk('contract','contract_id'),'CONSTRAINT uq_contract_pair UNIQUE (player_id, club_id)','INDEX ix_contract_club (club_id)',fk('contract','player_id','player','player_id'),fk('contract','club_id','club','club_id')])
table('head_coach_role',[id('role_id'),'club_id BIGINT UNSIGNED NOT NULL'],[pk('head_coach_role','role_id'),'CONSTRAINT uq_head_coach_role_club UNIQUE (club_id)',fk('head_coach_role','club_id','club','club_id')])
table('tx_registry',[id('tx_id'),'tx_time DATETIME(6) NOT NULL','author VARCHAR(128) NOT NULL','reason TEXT NOT NULL'],[pk('tx_registry','tx_id')])
table('tx_event_tag',['tx_id BIGINT UNSIGNED NOT NULL','event_code CHAR(2) NOT NULL'],[pk('tx_event_tag','tx_id, event_code'),fk('tx_event_tag','tx_id','tx_registry','tx_id'),"CONSTRAINT ck_tx_event_tag_code CHECK (event_code IN ('E1','E2','E3','E4','E5','E6','E7','E8','E9'))"])
models={
 'club_version':('club_id','club',['club_name VARCHAR(120) NOT NULL','budget_eur DECIMAL(14,2) NOT NULL'],['club_name','budget_eur'],['CONSTRAINT ck_club_version_budget CHECK (budget_eur >= 0)']),
 'contract_version':('contract_id','contract',['agreement_kind VARCHAR(9) NOT NULL','salary_eur DECIMAL(12,2) NOT NULL'],['agreement_kind','salary_eur'],["CONSTRAINT ck_contract_version_kind CHECK (agreement_kind IN ('PERMANENT','LOAN'))",'CONSTRAINT ck_contract_version_salary CHECK (salary_eur >= 0)']),
 'head_coach_role_version':('role_id','head_coach_role',['coach_id BIGINT UNSIGNED NOT NULL'],['coach_id'],['INDEX ix_head_coach_role_version_coach (coach_id)',fk('head_coach_role_version','coach_id','coach','coach_id')])}
for t,(key,parent,business,names,extra) in models.items():
 table(t,[id('version_id'),key+' BIGINT UNSIGNED NOT NULL']+business+['valid_from DATE NOT NULL',"valid_to DATE NOT NULL DEFAULT '9999-12-31'",'tx_from DATETIME(6) NOT NULL',"tx_to DATETIME(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999'",'tx_id BIGINT UNSIGNED NOT NULL'],[pk(t,'version_id'),f'INDEX ix_{t}_asof ({key}, tx_to, valid_from)',f'INDEX ix_{t}_tx (tx_id)',fk(t,key,parent,key),fk(t,'tx_id','tx_registry','tx_id'),f'CONSTRAINT ck_{t}_valid CHECK (valid_from < valid_to)',f'CONSTRAINT ck_{t}_tx CHECK (tx_from < tx_to)']+extra)
table('query_params',['params_id TINYINT UNSIGNED NOT NULL','valid_at DATE NOT NULL','known_at DATETIME(6) NOT NULL','period_start DATE NOT NULL','period_end DATE NOT NULL','subject_id BIGINT UNSIGNED NOT NULL'],[pk('query_params','params_id'),'CONSTRAINT ck_query_params_singleton CHECK (params_id = 1)','CONSTRAINT ck_query_params_period CHECK (period_start < period_end)'])
add("INSERT INTO query_params VALUES (1,'2026-03-02','2026-03-16 12:00:00.000000','2025-07-01','2026-07-01',1);")
add("""
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
""")
for t in ['tx_registry','tx_event_tag']:
 for op in ['UPDATE','DELETE']:
  add(f"CREATE TRIGGER tr_{t}_{op.lower()} BEFORE {op} ON {t} FOR EACH ROW\nSIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_METADATA: immutable {t}'$$")
for t,fields in [('contract',['contract_id','player_id','club_id']),('head_coach_role',['role_id','club_id'])]:
 condition=' OR '.join(f'NOT (NEW.{c} <=> OLD.{c})' for c in fields)
 add(f"CREATE TRIGGER tr_{t}_identity BEFORE UPDATE ON {t} FOR EACH ROW\nBEGIN\n IF {condition} THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_ANCHOR: stable identity'; END IF;\nEND$$")
for t,(key,parent,business,names,extra) in models.items():
 add(f"""CREATE TRIGGER tr_{t}_insert BEFORE INSERT ON {t} FOR EACH ROW
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
END$$""")
 protected=['version_id',key]+names+['valid_from','valid_to','tx_from','tx_id']
 condition=' OR\n    '.join((f'NOT (BINARY NEW.{c} <=> BINARY OLD.{c})' if c in ['club_name','agreement_kind'] else f'NOT (NEW.{c} <=> OLD.{c})') for c in protected)
 add(f"""CREATE TRIGGER tr_{t}_update BEFORE UPDATE ON {t} FOR EACH ROW
BEGIN
 DECLARE v_now DATETIME(6);
 DECLARE v_close DATETIME(6);
 IF OLD.tx_to <> '9999-12-31 23:59:59.999999' THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_CLOSED: history is immutable'; END IF;
 IF {condition} THEN
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
CREATE TRIGGER tr_{t}_delete BEFORE DELETE ON {t} FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_DELETE: physical deletion forbidden'$$""")
add('DELIMITER ;')
add("""
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
""")
parts=[]
for t,(key,*_) in models.items():
 parts.append(f"""SELECT 'I1' AS invariant_code, '{t}' AS source_table,
 a.{key} AS business_key, a.version_id, b.version_id AS conflicting_version_id,
 CONCAT('{key}=', a.{key}, ': overlapping current valid periods') AS details
 FROM {t} a JOIN {t} b ON a.{key} = b.{key} AND a.version_id < b.version_id
 AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to
 WHERE a.tx_to = '9999-12-31 23:59:59.999999' AND b.tx_to = '9999-12-31 23:59:59.999999'""")
for t,key,anchor in [('contract_version','contract_id','contract'),('head_coach_role_version','role_id','head_coach_role')]:
 parts.append(f"""SELECT 'I2', '{t}', v.{key}, v.version_id, CAST(NULL AS UNSIGNED),
 CONCAT('{key}=',v.{key},': club_id=', a.club_id, ' does not cover [',v.valid_from,',',v.valid_to,')')
 FROM {t} v JOIN {anchor} a ON a.{key} = v.{key}
 WHERE v.tx_to = '9999-12-31 23:59:59.999999'
 AND NOT EXISTS (SELECT 1 FROM parent_union p WHERE p.club_id = a.club_id
                 AND p.valid_from <= v.valid_from AND v.valid_to <= p.valid_to)""")
parts.append("""SELECT 'I3', 'head_coach_role_version', ra.club_id, a.version_id, b.version_id,
 CONCAT('club_id=',ra.club_id,': multiple current head coach assignments')
 FROM head_coach_role_version a JOIN head_coach_role ra ON ra.role_id = a.role_id
 JOIN head_coach_role rb ON rb.club_id = ra.club_id
 JOIN head_coach_role_version b ON b.role_id = rb.role_id AND a.version_id < b.version_id
 AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to
 WHERE a.tx_to = '9999-12-31 23:59:59.999999' AND b.tx_to = '9999-12-31 23:59:59.999999'""")
add('\nUNION ALL\n'.join(parts)+';\n')
(root/'01_schema.sql').write_text('\n'.join(S))
(root/'00_create_database.sql').write_text("-- Non-destructive. Requires CREATE permission for this database.\nCREATE DATABASE IF NOT EXISTS two_clocks_cabd CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\n")
