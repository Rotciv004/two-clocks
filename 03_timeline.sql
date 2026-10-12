-- Part B, standalone MariaDB SQL. Select database in the client; no hardcoded USE.
-- Fresh connection, fail-fast, NEVER --force. No persistent helper DDL/API.
-- E1/T01 is exclusively in 02_data.sql; T02-T38 exclusively in 03_timeline.sql.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
SET SESSION sql_mode='STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET @sim_now=NULL, @write_tx_id=NULL;
DELIMITER $$
BEGIN NOT ATOMIC
 IF DATABASE() IS NULL OR @@in_transaction THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_PRECONDITION: select database and use a fresh connection'; END IF;
END$$
DELIMITER ;
CREATE TEMPORARY TABLE p2_before_club_version LIKE club_version;
CREATE TEMPORARY TABLE p2_before_contract_version LIKE contract_version;
CREATE TEMPORARY TABLE p2_before_head_coach_role_version LIKE head_coach_role_version;


-- BEGIN EVENT T02: E3 / transfer
-- Transfer P001 la FC Târnava, înregistrat după închiderea ferestrei fictive.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T02' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=1 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T01')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T02 requires exactly prefix T01-T01; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-09-10 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T02 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-09-10 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T02: Transfer P001 la FC Târnava, înregistrat după închiderea ferestrei fictive.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P001' AND c.club_code='CL01') AND valid_from<='2025-08-31' AND '2025-08-31'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-08-31',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P001' AND c.club_code='CL06';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P001' AND c.club_code='CL06'),'PERMANENT',1510.00,'2025-08-31','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T02 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T02 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T02 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T02 Q0 violations -> rollback'; END IF;
SELECT 'T02' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T02' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T02


-- BEGIN EVENT T03: E3 / transfer
-- Transfer P002 la FC Ardeal, înregistrat târziu.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T03' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=2 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T02')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T03 requires exactly prefix T01-T02; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-09-15 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T03 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-09-15 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T03: Transfer P002 la FC Ardeal, înregistrat târziu.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P002' AND c.club_code='CL01') AND valid_from<='2025-08-30' AND '2025-08-30'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-08-30',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P002' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P002' AND c.club_code='CL02'),'PERMANENT',1520.00,'2025-08-30','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T03 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T03 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T03 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T03 Q0 violations -> rollback'; END IF;
SELECT 'T03' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T03' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T03


-- BEGIN EVENT T04: E3 / transfer
-- Transfer P003 la FC Mureș, înregistrat târziu.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T04' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=3 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T03')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T04 requires exactly prefix T01-T03; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-09-22 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T04 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-09-22 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T04: Transfer P003 la FC Mureș, înregistrat târziu.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P003' AND c.club_code='CL01') AND valid_from<='2025-08-29' AND '2025-08-29'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-08-29',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P003' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P003' AND c.club_code='CL03'),'PERMANENT',1530.00,'2025-08-29','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T04 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T04 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T04 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T04 Q0 violations -> rollback'; END IF;
SELECT 'T04' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T04' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T04


-- BEGIN EVENT T05: E2 / budget
-- FC Someș anunță majorarea bugetului pentru noiembrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T05' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=4 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T04')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T05 requires exactly prefix T01-T04; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-10-05 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T05 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-10-05 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T05: FC Someș anunță majorarea bugetului pentru noiembrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2');
SET v_old=(SELECT version_id FROM club_version WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL01') AND valid_from<='2025-11-01' AND '2025-11-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT budget_eur FROM club_version WHERE version_id=v_old)=1000000),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected old numeric value'; END IF;
UPDATE club_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,budget_eur,valid_from,'2025-11-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,1100000.00,'2025-11-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T05 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T05 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T05 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T05 Q0 violations -> rollback'; END IF;
SELECT 'T05' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T05' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T05


-- BEGIN EVENT T06: E3 / transfer
-- Transfer P004 la FC Apuseni, înregistrat târziu.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T06' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=5 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T05')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T06 requires exactly prefix T01-T05; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-10-12 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T06 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-10-12 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T06: Transfer P004 la FC Apuseni, înregistrat târziu.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P004' AND c.club_code='CL01') AND valid_from<='2025-08-28' AND '2025-08-28'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-08-28',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P004' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P004' AND c.club_code='CL04'),'PERMANENT',1540.00,'2025-08-28','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T06 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T06 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T06 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T06 Q0 violations -> rollback'; END IF;
SELECT 'T06' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T06' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T06


-- BEGIN EVENT T07: E3 / transfer
-- Transfer P005 la FC Criș, înregistrat târziu.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T07' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=6 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T06')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T07 requires exactly prefix T01-T06; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-10-20 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T07 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-10-20 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T07: Transfer P005 la FC Criș, înregistrat târziu.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P005' AND c.club_code='CL01') AND valid_from<='2025-08-27' AND '2025-08-27'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-08-27',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P005' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P005' AND c.club_code='CL05'),'PERMANENT',1550.00,'2025-08-27','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T07 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T07 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T07 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T07 Q0 violations -> rollback'; END IF;
SELECT 'T07' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T07' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T07


-- BEGIN EVENT T08: E2 / budget
-- FC Ardeal anunță bugetul din decembrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T08' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=7 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T07')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T08 requires exactly prefix T01-T07; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-11-10 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T08 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-11-10 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T08: FC Ardeal anunță bugetul din decembrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2');
SET v_old=(SELECT version_id FROM club_version WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL02') AND valid_from<='2025-12-01' AND '2025-12-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT budget_eur FROM club_version WHERE version_id=v_old)=1100000),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected old numeric value'; END IF;
UPDATE club_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,budget_eur,valid_from,'2025-12-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,1200000.00,'2025-12-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T08 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T08 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T08 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T08 Q0 violations -> rollback'; END IF;
SELECT 'T08' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T08' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T08


-- BEGIN EVENT T09: E2 / budget
-- FC Mureș anunță bugetul din ianuarie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T09' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=8 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T08')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T09 requires exactly prefix T01-T08; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-12-01 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T09 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-12-01 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T09: FC Mureș anunță bugetul din ianuarie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2');
SET v_old=(SELECT version_id FROM club_version WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL03') AND valid_from<='2026-01-01' AND '2026-01-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT budget_eur FROM club_version WHERE version_id=v_old)=1200000),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected old numeric value'; END IF;
UPDATE club_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,budget_eur,valid_from,'2026-01-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,1300000.00,'2026-01-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T09 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T09 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T09 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T09 Q0 violations -> rollback'; END IF;
SELECT 'T09' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T09' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T09


-- BEGIN EVENT T10: E5 / end
-- P013 părăsește real CL02 la 1 decembrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T10' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=9 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T09')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T10 requires exactly prefix T01-T09; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-12-03 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T10 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-12-03 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T10: P013 părăsește real CL02 la 1 decembrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E5');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P013' AND c.club_code='CL02') AND valid_from<='2025-12-01' AND '2025-12-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-12-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T10 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T10 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T10 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T10 Q0 violations -> rollback'; END IF;
SELECT 'T10' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T10' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T10


-- BEGIN EVENT T11: E5 / end
-- P014 părăsește real CL02 la 15 decembrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T11' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=10 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T10')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T11 requires exactly prefix T01-T10; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-12-18 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T11 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-12-18 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T11: P014 părăsește real CL02 la 15 decembrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E5');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P014' AND c.club_code='CL02') AND valid_from<='2025-12-15' AND '2025-12-15'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-12-15',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T11 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T11 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T11 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T11 Q0 violations -> rollback'; END IF;
SELECT 'T11' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T11' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T11


-- BEGIN EVENT T12: E5 / end
-- P015 părăsește real CL02 la 20 decembrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T12' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=11 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T11')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T12 requires exactly prefix T01-T11; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2025-12-23 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T12 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-12-23 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T12: P015 părăsește real CL02 la 20 decembrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E5');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P015' AND c.club_code='CL02') AND valid_from<='2025-12-20' AND '2025-12-20'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2025-12-20',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T12 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T12 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T12 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T12 Q0 violations -> rollback'; END IF;
SELECT 'T12' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T12' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T12


-- BEGIN EVENT T13: E3,E5 / end
-- Plecare P016 de la CL02, înregistrată cu șapte zile întârziere.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T13' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=12 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T12')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T13 requires exactly prefix T01-T12; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-01-08 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T13 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-01-08 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T13: Plecare P016 de la CL02, înregistrată cu șapte zile întârziere.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E5');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P016' AND c.club_code='CL02') AND valid_from<='2026-01-01' AND '2026-01-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-01-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T13 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T13 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T13 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T13 Q0 violations -> rollback'; END IF;
SELECT 'T13' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T13' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T13


-- BEGIN EVENT T14: E5 / end
-- P017 părăsește real CL02 la 15 ianuarie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T14' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=13 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T13')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T14 requires exactly prefix T01-T13; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-01-18 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T14 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-01-18 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T14: P017 părăsește real CL02 la 15 ianuarie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E5');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P017' AND c.club_code='CL02') AND valid_from<='2026-01-15' AND '2026-01-15'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-01-15',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T14 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T14 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T14 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T14 Q0 violations -> rollback'; END IF;
SELECT 'T14' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T14' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T14


-- BEGIN EVENT T15: E2,E6 / restart
-- Revenirea P013 este anunțată pentru februarie, pe aceeași ancoră.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T15' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=14 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T14')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T15 requires exactly prefix T01-T14; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-01-20 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T15 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-01-20 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T15: Revenirea P013 este anunțată pentru februarie, pe aceeași ancoră.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P013' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P013' AND c.club_code='CL02'),'PERMANENT',1130.00,'2026-02-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T15 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T15 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T15 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T15 Q0 violations -> rollback'; END IF;
SELECT 'T15' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T15' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T15


-- BEGIN EVENT T16: E3,E7 / role
-- H08 îl înlocuiește pe H03 la CL02 din 10 ianuarie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T16' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=15 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T15')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T16 requires exactly prefix T01-T15; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-01-20 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T16 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-01-20 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T16: H08 îl înlocuiește pe H03 la CL02 din 10 ianuarie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E7');
SET v_old=(SELECT version_id FROM head_coach_role_version WHERE role_id=(SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL02')) AND valid_from<='2026-01-10' AND '2026-01-10'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT coach_id FROM head_coach_role_version WHERE version_id=v_old)=(SELECT coach_id FROM coach WHERE coach_code='H03')),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected old coach'; END IF;
UPDATE head_coach_role_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,coach_id,valid_from,'2026-01-10',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,(SELECT coach_id FROM coach WHERE coach_code='H08'),'2026-01-10',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T16 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T16 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T16 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T16 Q0 violations -> rollback'; END IF;
SELECT 'T16' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T16' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T16


-- BEGIN EVENT T17: E2,E6 / restart
-- Revenirea P014 la CL02 este anunțată pentru martie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T17' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=16 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T16')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T17 requires exactly prefix T01-T16; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-02-15 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T17 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-02-15 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T17: Revenirea P014 la CL02 este anunțată pentru martie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P014' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P014' AND c.club_code='CL02'),'PERMANENT',1140.00,'2026-03-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T17 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T17 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T17 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T17 Q0 violations -> rollback'; END IF;
SELECT 'T17' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T17' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T17


-- BEGIN EVENT T18: E3,E7 / role
-- CL01 înregistrează demiterea/înlocuirea H01 cu H02, inițial datată 1 martie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T18' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=17 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T17')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T18 requires exactly prefix T01-T17; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-03-10 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T18 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-03-10 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T18: CL01 înregistrează demiterea/înlocuirea H01 cu H02, inițial datată 1 martie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E7');
SET v_old=(SELECT version_id FROM head_coach_role_version WHERE role_id=(SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL01')) AND valid_from<='2026-03-01' AND '2026-03-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT coach_id FROM head_coach_role_version WHERE version_id=v_old)=(SELECT coach_id FROM coach WHERE coach_code='H01')),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected old coach'; END IF;
UPDATE head_coach_role_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,coach_id,valid_from,'2026-03-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,(SELECT coach_id FROM coach WHERE coach_code='H02'),'2026-03-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T18 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T18 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T18 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T18 Q0 violations -> rollback'; END IF;
SELECT 'T18' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T18' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T18


-- BEGIN EVENT T19: E3,E4 / role_correction
-- Corecție T18: data reală a înlocuirii este 3 martie, nu 1 martie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T19' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=18 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T18')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T19 requires exactly prefix T01-T18; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-03-15 11:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T19 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-03-15 11:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T19: Corecție T18: data reală a înlocuirii este 3 martie, nu 1 martie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E4');
SET v_old=(SELECT version_id FROM head_coach_role_version WHERE role_id=(SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL01')) AND coach_id=(SELECT coach_id FROM coach WHERE coach_code='H01') AND tx_to='9999-12-31 23:59:59.999999');
SET v_old2=(SELECT version_id FROM head_coach_role_version WHERE role_id=(SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL01')) AND coach_id=(SELECT coach_id FROM coach WHERE coach_code='H02') AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL AND v_old2 IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T19 two current beliefs'; END IF;
UPDATE head_coach_role_version SET tx_to=v_time WHERE version_id IN(v_old,v_old2) AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=2),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 2 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,coach_id,valid_from,'2026-03-03',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,coach_id,'2026-03-03',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old2;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T19 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T19 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T19 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T19 Q0 violations -> rollback'; END IF;
SELECT 'T19' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T19' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T19


-- BEGIN EVENT T20: E3,E6 / restart
-- P015 revine la CL02 după pauză; revenirea este înregistrată târziu.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T20' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=19 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T19')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T20 requires exactly prefix T01-T19; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-03-20 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T20 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-03-20 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T20: P015 revine la CL02 după pauză; revenirea este înregistrată târziu.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P015' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P015' AND c.club_code='CL02'),'PERMANENT',1150.00,'2026-03-10','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T20 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T20 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T20 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T20 Q0 violations -> rollback'; END IF;
SELECT 'T20' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T20' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T20


-- BEGIN EVENT T21: E3 / loan
-- Afirmație eronată: P060 ar fi împrumutat la CL06 în aprilie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T21' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=20 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T20')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T21 requires exactly prefix T01-T20; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-04-10 14:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T21 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-04-10 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T21: Afirmație eronată: P060 ar fi împrumutat la CL06 în aprilie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P060' AND c.club_code='CL06';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P060' AND c.club_code='CL06'),'LOAN',600.00,'2026-04-01','2026-05-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T21 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T21 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T21 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T21 Q0 violations -> rollback'; END IF;
SELECT 'T21' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T21' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T21


-- BEGIN EVENT T22: E2 / salary
-- Salariul P025 va crește din mai; se păstrează prefixul cu 1250 EUR.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T22' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=21 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T21')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T22 requires exactly prefix T01-T21; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-04-15 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T22 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-04-15 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T22: Salariul P025 va crește din mai; se păstrează prefixul cu 1250 EUR.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P025' AND c.club_code='CL03') AND valid_from<='2026-05-01' AND '2026-05-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1250),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected old numeric value'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-05-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1450.00,'2026-05-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T22 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T22 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T22 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T22 Q0 violations -> rollback'; END IF;
SELECT 'T22' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T22' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T22


-- BEGIN EVENT T23: E3,E4 / salary_correction
-- Corectează salariul inițial P026 la 1280 EUR.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T23' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=22 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T22')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T23 requires exactly prefix T01-T22; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-04-20 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T23 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-04-20 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T23: Corectează salariul inițial P026 la 1280 EUR.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E4');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P026' AND c.club_code='CL03') AND valid_from<='2025-07-01' AND '2025-07-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1260),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: correction expected wrong salary'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1280.00,valid_from,valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T23 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T23 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T23 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T23 Q0 violations -> rollback'; END IF;
SELECT 'T23' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T23' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T23


-- BEGIN EVENT T24: E3,E4 / salary_correction
-- Corectează salariul inițial P027 la 1290 EUR.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T24' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=23 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T23')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T24 requires exactly prefix T01-T23; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-04-22 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T24 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-04-22 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T24: Corectează salariul inițial P027 la 1290 EUR.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E4');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P027' AND c.club_code='CL03') AND valid_from<='2025-07-01' AND '2025-07-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1270),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: correction expected wrong salary'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1290.00,valid_from,valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T24 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T24 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T24 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T24 Q0 violations -> rollback'; END IF;
SELECT 'T24' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T24' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T24


-- BEGIN EVENT T25: E8 / retract
-- Retrage T21 ca niciodată adevărat; închide numai TT, fără înlocuire.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T25' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=24 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T24')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T25 requires exactly prefix T01-T24; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-04-25 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T25 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-04-25 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T25: Retrage T21 ca niciodată adevărat; închide numai TT, fără înlocuire.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E8');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P060' AND c.club_code='CL06') AND valid_from<='2026-04-01' AND '2026-04-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T25 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T25 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T25 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T25 Q0 violations -> rollback'; END IF;
SELECT 'T25' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T25' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T25


-- BEGIN EVENT T26: E3,E4 / salary_correction
-- Corectează T22 numai în sufixul din mai; prefixul anterior rămâne.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T26' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=25 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T25')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T26 requires exactly prefix T01-T25; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-05-10 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T26 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-05-10 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T26: Corectează T22 numai în sufixul din mai; prefixul anterior rămâne.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E4');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P025' AND c.club_code='CL03') AND valid_from<='2026-05-01' AND '2026-05-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1450),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: correction expected wrong salary'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1455.00,valid_from,valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T26 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T26 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T26 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T26 Q0 violations -> rollback'; END IF;
SELECT 'T26' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T26' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T26


-- BEGIN EVENT T27: E2 / salary
-- Anunță salariul P026 din iunie, plecând de la valoarea corectată.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T27' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=26 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T26')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T27 requires exactly prefix T01-T26; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-05-15 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T27 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-05-15 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T27: Anunță salariul P026 din iunie, plecând de la valoarea corectată.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P026' AND c.club_code='CL03') AND valid_from<='2026-06-01' AND '2026-06-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1280),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected old numeric value'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-06-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1480.00,'2026-06-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T27 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T27 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T27 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T27 Q0 violations -> rollback'; END IF;
SELECT 'T27' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T27' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T27


-- BEGIN EVENT T28: E3 / loan
-- Împrumut P006 la CL02 până în septembrie, fără închiderea contractului de origine.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T28' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=27 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T27')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T28 requires exactly prefix T01-T27; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-06-10 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T28 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-06-10 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T28: Împrumut P006 la CL02 până în septembrie, fără închiderea contractului de origine.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P006' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL02'),'LOAN',600.00,'2026-06-01','2026-09-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T28 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T28 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T28 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T28 Q0 violations -> rollback'; END IF;
SELECT 'T28' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T28' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T28


-- BEGIN EVENT T29: E3 / loan
-- Împrumut P007 la CL03, înregistrat cu nouă zile întârziere.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T29' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=28 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T28')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T29 requires exactly prefix T01-T28; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-06-10 11:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T29 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-06-10 11:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T29: Împrumut P007 la CL03, înregistrat cu nouă zile întârziere.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P007' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P007' AND c.club_code='CL03'),'LOAN',700.00,'2026-06-01','2026-09-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T29 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T29 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T29 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T29 Q0 violations -> rollback'; END IF;
SELECT 'T29' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T29' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T29


-- BEGIN EVENT T30: E3 / loan
-- Împrumut P008 la CL04, înregistrat cu nouă zile întârziere.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T30' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=29 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T29')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T30 requires exactly prefix T01-T29; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-06-10 12:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T30 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-06-10 12:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T30: Împrumut P008 la CL04, înregistrat cu nouă zile întârziere.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P008' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P008' AND c.club_code='CL04'),'LOAN',800.00,'2026-06-01','2026-09-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T30 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T30 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T30 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T30 Q0 violations -> rollback'; END IF;
SELECT 'T30' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T30' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T30


-- BEGIN EVENT T31: E2 / salary
-- Anunță salariul P027 din iulie, păstrând valoarea inițială corectată.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T31' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=30 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T30')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T31 requires exactly prefix T01-T30; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-06-15 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T31 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-06-15 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T31: Anunță salariul P027 din iulie, păstrând valoarea inițială corectată.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P027' AND c.club_code='CL03') AND valid_from<='2026-07-01' AND '2026-07-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1290),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected old numeric value'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-07-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1490.00,'2026-07-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T31 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T31 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T31 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T31 Q0 violations -> rollback'; END IF;
SELECT 'T31' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T31' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T31


-- BEGIN EVENT T32: E5 / end
-- Scurtează real împrumutul P006: se încheie la 1 iulie, nu 1 septembrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T32' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=31 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T31')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T32 requires exactly prefix T01-T31; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-07-05 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T32 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-07-05 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T32: Scurtează real împrumutul P006: se încheie la 1 iulie, nu 1 septembrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E5');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL02') AND valid_from<='2026-07-01' AND '2026-07-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-07-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T32 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T32 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T32 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T32 Q0 violations -> rollback'; END IF;
SELECT 'T32' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T32' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T32


-- BEGIN EVENT T33: E3,E4 / salary_correction
-- Corectează T31 numai în sufixul din iulie la 1495 EUR.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T33' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=32 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T32')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T33 requires exactly prefix T01-T32; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-07-10 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T33 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-07-10 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T33: Corectează T31 numai în sufixul din iulie la 1495 EUR.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E4');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P027' AND c.club_code='CL03') AND valid_from<='2026-07-01' AND '2026-07-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1490),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: correction expected wrong salary'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1495.00,valid_from,valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T33 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T33 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T33 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T33 Q0 violations -> rollback'; END IF;
SELECT 'T33' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T33' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T33


-- BEGIN EVENT T34: E2,E9 / multi
-- O singură decizie majorează bugetul CL04 și salariul P037 din august.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T34' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=33 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T33')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T34 requires exactly prefix T01-T33; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-07-15 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T34 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-07-15 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T34: O singură decizie majorează bugetul CL04 și salariul P037 din august.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E9');
SET v_old=(SELECT version_id FROM club_version WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL04') AND valid_from<='2026-08-01' AND '2026-08-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT budget_eur FROM club_version WHERE version_id=v_old)=1300000),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected old numeric value'; END IF;
UPDATE club_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,budget_eur,valid_from,'2026-08-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,1430000.00,'2026-08-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P037' AND c.club_code='CL04') AND valid_from<='2026-08-01' AND '2026-08-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1370),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected old numeric value'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-08-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1570.00,'2026-08-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T34 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T34 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T34 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T34 Q0 violations -> rollback'; END IF;
SELECT 'T34' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T34' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T34


-- BEGIN EVENT T35: E2,E9 / multi
-- O singură decizie majorează bugetul CL05 și salariul P049 din septembrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T35' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=34 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T34')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T35 requires exactly prefix T01-T34; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-08-15 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T35 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-08-15 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T35: O singură decizie majorează bugetul CL05 și salariul P049 din septembrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E9');
SET v_old=(SELECT version_id FROM club_version WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL05') AND valid_from<='2026-09-01' AND '2026-09-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT budget_eur FROM club_version WHERE version_id=v_old)=1400000),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected old numeric value'; END IF;
UPDATE club_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,budget_eur,valid_from,'2026-09-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,1540000.00,'2026-09-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P049' AND c.club_code='CL05') AND valid_from<='2026-09-01' AND '2026-09-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT salary_eur FROM contract_version WHERE version_id=v_old)=1490),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected old numeric value'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,salary_eur,valid_from,'2026-09-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT contract_id,agreement_kind,1740.00,'2026-09-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM contract_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T35 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T35 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T35 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T35 Q0 violations -> rollback'; END IF;
SELECT 'T35' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T35' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T35


-- BEGIN EVENT T36: E2,E7 / role
-- H01 este anunțat la CL03 din octombrie, după plecarea din CL01.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T36' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=35 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T35')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T36 requires exactly prefix T01-T35; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-09-01 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T36 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-09-01 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T36: H01 este anunțat la CL03 din octombrie, după plecarea din CL01.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E7');
SET v_old=(SELECT version_id FROM head_coach_role_version WHERE role_id=(SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL03')) AND valid_from<='2026-10-01' AND '2026-10-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT coach_id FROM head_coach_role_version WHERE version_id=v_old)=(SELECT coach_id FROM coach WHERE coach_code='H04')),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected old coach'; END IF;
UPDATE head_coach_role_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,coach_id,valid_from,'2026-10-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT role_id,(SELECT coach_id FROM coach WHERE coach_code='H01'),'2026-10-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM head_coach_role_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T36 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T36 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T36 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T36 Q0 violations -> rollback'; END IF;
SELECT 'T36' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T36' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T36


-- BEGIN EVENT T37: E2 / budget
-- CL06 anunță bugetul din noiembrie înainte să devină valabil.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T37' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=36 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T36')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T37 requires exactly prefix T01-T36; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-09-10 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T37 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-09-10 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T37: CL06 anunță bugetul din noiembrie înainte să devină valabil.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2');
SET v_old=(SELECT version_id FROM club_version WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL06') AND valid_from<='2026-11-01' AND '2026-11-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected one current affected version'; END IF;
IF NOT COALESCE(((SELECT budget_eur FROM club_version WHERE version_id=v_old)=1500000),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version expected old numeric value'; END IF;
UPDATE club_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,budget_eur,valid_from,'2026-11-01',v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_to,tx_id) SELECT club_id,club_name,1650000.00,'2026-11-01',valid_to,v_time,'9999-12-31 23:59:59.999999',@write_tx_id FROM club_version WHERE version_id=v_old;
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T37 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T37 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T37 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T37 Q0 violations -> rollback'; END IF;
SELECT 'T37' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T37' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T37


-- BEGIN EVENT T38: E2,E6 / restart
-- Reîncepe împrumutul P006 pe aceeași ancoră, după pauza iulie–octombrie.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_time DATETIME(6);
DECLARE v_id BIGINT UNSIGNED;
DECLARE v_old BIGINT UNSIGNED;
DECLARE v_old2 BIGINT UNSIGNED;
DECLARE v_locked BIGINT UNSIGNED;
DECLARE v_q0 BIGINT;
DECLARE v_errno INT;
DECLARE v_message TEXT;
DECLARE v_got_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT 'T38' AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 IF NOT COALESCE((v_got_lock=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: another replay is active'; END IF;
 START TRANSACTION;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT club_id FROM club ORDER BY club_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT player_id FROM player ORDER BY player_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT coach_id FROM coach ORDER BY coach_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT contract_id FROM contract ORDER BY contract_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT role_id FROM head_coach_role ORDER BY role_id FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;
IF NOT COALESCE(((SELECT COUNT(*) FROM tx_registry)=37 AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)='T37')=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T38 requires exactly prefix T01-T37; no automatic resume'; END IF;
IF NOT COALESCE(((SELECT MAX(tx_time) FROM tx_registry)<'2026-09-20 10:00:00.000000'),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T38 transaction order'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2026-09-20 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T38: Reîncepe împrumutul P006 pe aceeași ancoră, după pauza iulie–octombrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL02'),'LOAN',650.00,'2026-10-01','2026-12-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
UPDATE query_params SET valid_at='2026-03-02',known_at='2026-03-16 12:00:00.000000',period_start='2025-07-01',period_end='2026-07-01',subject_id=(SELECT club_id FROM club WHERE club_code='CL01') WHERE params_id=1;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T38 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T38 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T38 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T38 Q0 violations -> rollback'; END IF;
SELECT 'T38' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T38' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T38

DROP TEMPORARY TABLE p2_before_club_version;
DROP TEMPORARY TABLE p2_before_contract_version;
DROP TEMPORARY TABLE p2_before_head_coach_role_version;
SET @sim_now=NULL, @write_tx_id=NULL;
