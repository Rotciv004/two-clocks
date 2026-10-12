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


SET @sim_now='2026-01-20 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T15: Revenirea P013 este anunțată pentru februarie, pe aceeași ancoră.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P013' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P013' AND c.club_code='CL02'),'PERMANENT',1130.00,'2026-02-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


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


SET @sim_now='2026-02-15 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T17: Revenirea P014 la CL02 este anunțată pentru martie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P014' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P014' AND c.club_code='CL02'),'PERMANENT',1140.00,'2026-03-01','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


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


SET @sim_now='2026-03-20 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T20: P015 revine la CL02 după pauză; revenirea este înregistrată târziu.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P015' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P015' AND c.club_code='CL02'),'PERMANENT',1150.00,'2026-03-10','9999-12-31',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


SET @sim_now='2026-04-10 14:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T21: Afirmație eronată: P060 ar fi împrumutat la CL06 în aprilie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P060' AND c.club_code='CL06';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P060' AND c.club_code='CL06'),'LOAN',600.00,'2026-04-01','2026-05-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


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


SET @sim_now='2026-04-25 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T25: Retrage T21 ca niciodată adevărat; închide numai TT, fără înlocuire.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E8');
SET v_old=(SELECT version_id FROM contract_version WHERE contract_id=(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P060' AND c.club_code='CL06') AND valid_from<='2026-04-01' AND '2026-04-01'<valid_to AND tx_to='9999-12-31 23:59:59.999999');
IF NOT COALESCE((v_old IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: contract_version expected one current affected version'; END IF;
UPDATE contract_version SET tx_to=v_time WHERE version_id=v_old AND tx_to='9999-12-31 23:59:59.999999';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


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


SET @sim_now='2026-06-10 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T28: Împrumut P006 la CL02 până în septembrie, fără închiderea contractului de origine.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P006' AND c.club_code='CL02';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL02'),'LOAN',600.00,'2026-06-01','2026-09-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


SET @sim_now='2026-06-10 11:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T29: Împrumut P007 la CL03, înregistrat cu nouă zile întârziere.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P007' AND c.club_code='CL03';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P007' AND c.club_code='CL03'),'LOAN',700.00,'2026-06-01','2026-09-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


SET @sim_now='2026-06-10 12:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T30: Împrumut P008 la CL04, înregistrat cu nouă zile întârziere.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E3');
INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code='P008' AND c.club_code='CL04';
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P008' AND c.club_code='CL04'),'LOAN',800.00,'2026-06-01','2026-09-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;


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


SET @sim_now='2026-09-20 10:00:00.000000';
SET v_time=fn_effective_time();
INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,'Boar Victor — dataset fictiv','T38: Reîncepe împrumutul P006 pe aceeași ancoră, după pauza iulie–octombrie.');
SET @write_tx_id=LAST_INSERT_ID();
INSERT INTO tx_event_tag(tx_id,event_code) VALUES (@write_tx_id,'E2'),(@write_tx_id,'E6');
IF NOT COALESCE(((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL02') IS NOT NULL),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: restart reuses existing anchor'; END IF;
INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES((SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code='P006' AND c.club_code='CL02'),'LOAN',650.00,'2026-10-01','2026-12-01',v_time,@write_tx_id);
IF NOT COALESCE((ROW_COUNT()=1),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_ASSERT: expected 1 affected rows'; END IF;
UPDATE query_params SET valid_at='2026-03-02',known_at='2026-03-16 12:00:00.000000',period_start='2025-07-01',period_end='2026-07-01',subject_id=(SELECT club_id FROM club WHERE club_code='CL01') WHERE params_id=1;
