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


-- BEGIN EVENT T01: E1 / initial
-- Încărcare inițială: persoane fictive, cluburi, două sezoane, contracte și titulari; CL04 are două angajamente adiacente cu H05.
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
  SELECT 'T01' AS failed_event, v_errno AS error_code, v_message AS error_message,
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
IF NOT COALESCE(((SELECT COUNT(*) FROM player) + (SELECT COUNT(*) FROM coach) + (SELECT COUNT(*) FROM club) + (SELECT COUNT(*) FROM season) + (SELECT COUNT(*) FROM contract) + (SELECT COUNT(*) FROM head_coach_role) + (SELECT COUNT(*) FROM tx_registry) + (SELECT COUNT(*) FROM tx_event_tag) + (SELECT COUNT(*) FROM club_version) + (SELECT COUNT(*) FROM contract_version) + (SELECT COUNT(*) FROM head_coach_role_version)=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T01 requires an unpopulated database; refusing duplicate load'; END IF;
IF NOT COALESCE(((SELECT COUNT(*) FROM query_params)=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: query_params singleton required'; END IF;
DELETE FROM p2_before_club_version;
INSERT INTO p2_before_club_version SELECT * FROM club_version;
DELETE FROM p2_before_contract_version;
INSERT INTO p2_before_contract_version SELECT * FROM contract_version;
DELETE FROM p2_before_head_coach_role_version;
INSERT INTO p2_before_head_coach_role_version SELECT * FROM head_coach_role_version;
SET @sim_now='2025-07-01 09:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T01: Încărcare inițială: persoane fictive, cluburi, două sezoane, contracte și titulari; CL04 are două angajamente adiacente cu H05.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E1');
INSERT INTO player(player_code,full_name,birth_date) VALUES
('P001','Jucător Fictiv 001','1995-01-01'),
('P002','Jucător Fictiv 002','1995-02-07'),
('P003','Jucător Fictiv 003','1995-03-16'),
('P004','Jucător Fictiv 004','1995-04-22'),
('P005','Jucător Fictiv 005','1995-05-29'),
('P006','Jucător Fictiv 006','1995-07-05'),
('P007','Jucător Fictiv 007','1995-08-11'),
('P008','Jucător Fictiv 008','1995-09-17'),
('P009','Jucător Fictiv 009','1995-10-24'),
('P010','Jucător Fictiv 010','1995-11-30'),
('P011','Jucător Fictiv 011','1996-01-06'),
('P012','Jucător Fictiv 012','1996-02-12'),
('P013','Jucător Fictiv 013','1996-03-20'),
('P014','Jucător Fictiv 014','1996-04-26'),
('P015','Jucător Fictiv 015','1996-06-02'),
('P016','Jucător Fictiv 016','1996-07-09'),
('P017','Jucător Fictiv 017','1996-08-15'),
('P018','Jucător Fictiv 018','1996-09-21'),
('P019','Jucător Fictiv 019','1996-10-28'),
('P020','Jucător Fictiv 020','1996-12-04'),
('P021','Jucător Fictiv 021','1997-01-10'),
('P022','Jucător Fictiv 022','1997-02-16'),
('P023','Jucător Fictiv 023','1997-03-25'),
('P024','Jucător Fictiv 024','1997-05-01'),
('P025','Jucător Fictiv 025','1997-06-07'),
('P026','Jucător Fictiv 026','1997-07-14'),
('P027','Jucător Fictiv 027','1997-08-20'),
('P028','Jucător Fictiv 028','1997-09-26'),
('P029','Jucător Fictiv 029','1997-11-02'),
('P030','Jucător Fictiv 030','1997-12-09'),
('P031','Jucător Fictiv 031','1998-01-15'),
('P032','Jucător Fictiv 032','1998-02-21'),
('P033','Jucător Fictiv 033','1998-03-30'),
('P034','Jucător Fictiv 034','1998-05-06'),
('P035','Jucător Fictiv 035','1998-06-12'),
('P036','Jucător Fictiv 036','1998-07-19'),
('P037','Jucător Fictiv 037','1998-08-25'),
('P038','Jucător Fictiv 038','1998-10-01'),
('P039','Jucător Fictiv 039','1998-11-07'),
('P040','Jucător Fictiv 040','1998-12-14'),
('P041','Jucător Fictiv 041','1999-01-20'),
('P042','Jucător Fictiv 042','1999-02-26'),
('P043','Jucător Fictiv 043','1999-04-04'),
('P044','Jucător Fictiv 044','1999-05-11'),
('P045','Jucător Fictiv 045','1999-06-17'),
('P046','Jucător Fictiv 046','1999-07-24'),
('P047','Jucător Fictiv 047','1999-08-30'),
('P048','Jucător Fictiv 048','1999-10-06'),
('P049','Jucător Fictiv 049','1999-11-12'),
('P050','Jucător Fictiv 050','1999-12-19'),
('P051','Jucător Fictiv 051','2000-01-25'),
('P052','Jucător Fictiv 052','2000-03-02'),
('P053','Jucător Fictiv 053','2000-04-08'),
('P054','Jucător Fictiv 054','2000-05-15'),
('P055','Jucător Fictiv 055','2000-06-21'),
('P056','Jucător Fictiv 056','2000-07-28'),
('P057','Jucător Fictiv 057','2000-09-03'),
('P058','Jucător Fictiv 058','2000-10-10'),
('P059','Jucător Fictiv 059','2000-11-16'),
('P060','Jucător Fictiv 060','2000-12-23');
IF NOT COALESCE((ROW_COUNT()=60),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 60 affected rows'; END IF;
INSERT INTO coach(coach_code,full_name,birth_date) VALUES
('H01','Andrei Ionescu','1970-01-01'),
('H02','Mihai Popescu','1971-01-01'),
('H03','Radu Marin','1972-01-01'),
('H04','Vlad Stan','1973-01-01'),
('H05','Sorin Dima','1974-01-01'),
('H06','Dan Rusu','1975-01-01'),
('H07','Paul Muntean','1976-01-01'),
('H08','Alex Matei','1977-01-01');
IF NOT COALESCE((ROW_COUNT()=8),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 8 affected rows'; END IF;
INSERT INTO club(club_code) VALUES ('CL01'),('CL02'),('CL03'),('CL04'),('CL05'),('CL06');
IF NOT COALESCE((ROW_COUNT()=6),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 6 affected rows'; END IF;
INSERT INTO season(season_name,period_start,period_end) VALUES ('2025/2026','2025-07-01','2026-07-01'),('2026/2027','2026-07-01','2027-07-01');
IF NOT COALESCE((ROW_COUNT()=2),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 2 affected rows'; END IF;
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,tx_from,tx_id) VALUES((SELECT club_id FROM club WHERE club_code='CL01'),'FC Someș',1000000.00,'2025-07-01',v_time,@write_tx_id);
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,tx_from,tx_id) VALUES((SELECT club_id FROM club WHERE club_code='CL02'),'FC Ardeal',1100000.00,'2025-07-01',v_time,@write_tx_id);
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,tx_from,tx_id) VALUES((SELECT club_id FROM club WHERE club_code='CL03'),'FC Mureș',1200000.00,'2025-07-01',v_time,@write_tx_id);
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,tx_from,tx_id) VALUES((SELECT club_id FROM club WHERE club_code='CL04'),'FC Apuseni',1300000.00,'2025-07-01',v_time,@write_tx_id);
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,tx_from,tx_id) VALUES((SELECT club_id FROM club WHERE club_code='CL05'),'FC Criș',1400000.00,'2025-07-01',v_time,@write_tx_id);
INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,tx_from,tx_id) VALUES((SELECT club_id FROM club WHERE club_code='CL06'),'FC Târnava',1500000.00,'2025-07-01',v_time,@write_tx_id);
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P001' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P001' AND c.club_code='CL01'),'PERMANENT',1010.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P002' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P002' AND c.club_code='CL01'),'PERMANENT',1020.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P003' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P003' AND c.club_code='CL01'),'PERMANENT',1030.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P004' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P004' AND c.club_code='CL01'),'PERMANENT',1040.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P005' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P005' AND c.club_code='CL01'),'PERMANENT',1050.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P006' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL01'),'PERMANENT',1060.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P007' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P007' AND c.club_code='CL01'),'PERMANENT',1070.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P008' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P008' AND c.club_code='CL01'),'PERMANENT',1080.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P009' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P009' AND c.club_code='CL01'),'PERMANENT',1090.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P010' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P010' AND c.club_code='CL01'),'PERMANENT',1100.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P011' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P011' AND c.club_code='CL01'),'PERMANENT',1110.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P012' AND c.club_code='CL01';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P012' AND c.club_code='CL01'),'PERMANENT',1120.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P013' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P013' AND c.club_code='CL02'),'PERMANENT',1130.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P014' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P014' AND c.club_code='CL02'),'PERMANENT',1140.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P015' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P015' AND c.club_code='CL02'),'PERMANENT',1150.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P016' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P016' AND c.club_code='CL02'),'PERMANENT',1160.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P017' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P017' AND c.club_code='CL02'),'PERMANENT',1170.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P018' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P018' AND c.club_code='CL02'),'PERMANENT',1180.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P019' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P019' AND c.club_code='CL02'),'PERMANENT',1190.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P020' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P020' AND c.club_code='CL02'),'PERMANENT',1200.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P021' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P021' AND c.club_code='CL02'),'PERMANENT',1210.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P022' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P022' AND c.club_code='CL02'),'PERMANENT',1220.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P023' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P023' AND c.club_code='CL02'),'PERMANENT',1230.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P024' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P024' AND c.club_code='CL02'),'PERMANENT',1240.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P025' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P025' AND c.club_code='CL03'),'PERMANENT',1250.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P026' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P026' AND c.club_code='CL03'),'PERMANENT',1260.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P027' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P027' AND c.club_code='CL03'),'PERMANENT',1270.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P028' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P028' AND c.club_code='CL03'),'PERMANENT',1280.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P029' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P029' AND c.club_code='CL03'),'PERMANENT',1290.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P030' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P030' AND c.club_code='CL03'),'PERMANENT',1300.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P031' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P031' AND c.club_code='CL03'),'PERMANENT',1310.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P032' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P032' AND c.club_code='CL03'),'PERMANENT',1320.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P033' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P033' AND c.club_code='CL03'),'PERMANENT',1330.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P034' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P034' AND c.club_code='CL03'),'PERMANENT',1340.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P035' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P035' AND c.club_code='CL03'),'PERMANENT',1350.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P036' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P036' AND c.club_code='CL03'),'PERMANENT',1360.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P037' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P037' AND c.club_code='CL04'),'PERMANENT',1370.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P038' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P038' AND c.club_code='CL04'),'PERMANENT',1380.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P039' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P039' AND c.club_code='CL04'),'PERMANENT',1390.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P040' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P040' AND c.club_code='CL04'),'PERMANENT',1400.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P041' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P041' AND c.club_code='CL04'),'PERMANENT',1410.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P042' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P042' AND c.club_code='CL04'),'PERMANENT',1420.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P043' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P043' AND c.club_code='CL04'),'PERMANENT',1430.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P044' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P044' AND c.club_code='CL04'),'PERMANENT',1440.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P045' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P045' AND c.club_code='CL04'),'PERMANENT',1450.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P046' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P046' AND c.club_code='CL04'),'PERMANENT',1460.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P047' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P047' AND c.club_code='CL04'),'PERMANENT',1470.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P048' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P048' AND c.club_code='CL04'),'PERMANENT',1480.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P049' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P049' AND c.club_code='CL05'),'PERMANENT',1490.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P050' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P050' AND c.club_code='CL05'),'PERMANENT',1500.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P051' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P051' AND c.club_code='CL05'),'PERMANENT',1510.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P052' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P052' AND c.club_code='CL05'),'PERMANENT',1520.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P053' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P053' AND c.club_code='CL05'),'PERMANENT',1530.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P054' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P054' AND c.club_code='CL05'),'PERMANENT',1540.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P055' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P055' AND c.club_code='CL05'),'PERMANENT',1550.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P056' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P056' AND c.club_code='CL05'),'PERMANENT',1560.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P057' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P057' AND c.club_code='CL05'),'PERMANENT',1570.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P058' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P058' AND c.club_code='CL05'),'PERMANENT',1580.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P059' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P059' AND c.club_code='CL05'),'PERMANENT',1590.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P060' AND c.club_code='CL05';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P060' AND c.club_code='CL05'),'PERMANENT',1600.00,'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO head_coach_role(club_id) VALUES((SELECT club_id FROM club WHERE club_code='CL01'));
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL01')),(SELECT coach_id FROM coach WHERE coach_code='H01'),'2025-07-01','9999-12-31',v_time,@write_tx_id);
INSERT INTO head_coach_role(club_id) VALUES((SELECT club_id FROM club WHERE club_code='CL02'));
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL02')),(SELECT coach_id FROM coach WHERE coach_code='H03'),'2025-07-01','9999-12-31',v_time,@write_tx_id);
INSERT INTO head_coach_role(club_id) VALUES((SELECT club_id FROM club WHERE club_code='CL03'));
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL03')),(SELECT coach_id FROM coach WHERE coach_code='H04'),'2025-07-01','9999-12-31',v_time,@write_tx_id);
INSERT INTO head_coach_role(club_id) VALUES((SELECT club_id FROM club WHERE club_code='CL04'));
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL04')),(SELECT coach_id FROM coach WHERE coach_code='H05'),'2025-07-01','2026-07-01',v_time,@write_tx_id);
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL04')),(SELECT coach_id FROM coach WHERE coach_code='H05'),'2026-07-01','9999-12-31',v_time,@write_tx_id);
INSERT INTO head_coach_role(club_id) VALUES((SELECT club_id FROM club WHERE club_code='CL05'));
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL05')),(SELECT coach_id FROM coach WHERE coach_code='H06'),'2025-07-01','9999-12-31',v_time,@write_tx_id);
INSERT INTO head_coach_role(club_id) VALUES((SELECT club_id FROM club WHERE club_code='CL06'));
INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT role_id FROM head_coach_role WHERE club_id=(SELECT club_id FROM club WHERE club_code='CL06')),(SELECT coach_id FROM coach WHERE coach_code='H07'),'2025-07-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE(((SELECT COUNT(*) FROM club_version)=6 AND (SELECT COUNT(*) FROM contract_version)=60 AND (SELECT COUNT(*) FROM head_coach_role_version)=7),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T01 exactly 73 versions'; END IF;
UPDATE query_params SET subject_id=(SELECT club_id FROM club WHERE club_code='CL01') WHERE params_id=1;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_club_version b LEFT JOIN club_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.club_id <=> a.club_id) OR NOT (BINARY b.club_name <=> BINARY a.club_name) OR NOT (b.budget_eur <=> a.budget_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T01 I4 club_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM club_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: club_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_contract_version b LEFT JOIN contract_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.contract_id <=> a.contract_id) OR NOT (BINARY b.agreement_kind <=> BINARY a.agreement_kind) OR NOT (b.salary_eur <=> a.salary_eur) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T01 I4 contract_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM contract_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version registry time and order'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM p2_before_head_coach_role_version b LEFT JOIN head_coach_role_version a USING(version_id) WHERE a.version_id IS NULL OR NOT (b.version_id <=> a.version_id) OR NOT (b.role_id <=> a.role_id) OR NOT (b.coach_id <=> a.coach_id) OR NOT (b.valid_from <=> a.valid_from) OR NOT (b.valid_to <=> a.valid_to) OR NOT (b.tx_from <=> a.tx_from) OR NOT (b.tx_id <=> a.tx_id) OR (b.tx_to <> '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to) OR (b.tx_to = '9999-12-31 23:59:59.999999' AND a.tx_to<>b.tx_to AND a.tx_to<>v_time))),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T01 I4 head_coach_role_version unchanged except legitimate close'; END IF;
IF NOT COALESCE((NOT EXISTS(SELECT 1 FROM head_coach_role_version a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: head_coach_role_version registry time and order'; END IF;
SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;
IF NOT COALESCE((v_q0=0),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: T01 Q0 violations -> rollback'; END IF;
SELECT 'T01' AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;
COMMIT;
SET @sim_now=NULL, @write_tx_id=NULL;
DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));
SELECT 'T01' AS committed_event;
END$$
DELIMITER ;
-- END EVENT T01

DROP TEMPORARY TABLE p2_before_club_version;
DROP TEMPORARY TABLE p2_before_contract_version;
DROP TEMPORARY TABLE p2_before_head_coach_role_version;
SET @sim_now=NULL, @write_tx_id=NULL;
