-- Exemple complete, copiate VERBATIM din cronologia verificată.
-- Nu rula pe two_clocks_cabd. Se selectează UN SINGUR bloc pe clona
-- de replay aflată exact după T17 (T18), T18 (T19), respectiv T24 (T25).
-- Precondiții/lock-uri/handler ROLLBACK, snapshot I4/Q0 și COMMIT incluse.
-- Headerul comun de mai jos pregătește tabelele temporare în fiecare sesiune.

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



-- SELECT ONLY THIS EVENT: T18
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

-- SELECT ONLY THIS EVENT: T19
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

-- SELECT ONLY THIS EVENT: T25
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
