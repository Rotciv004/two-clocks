-- Run with a MariaDB/MySQL client that stops on SQL error; do not use --force.
-- Requires 01_schema.sql and enforced CHECK constraints. Select the database externally.
-- On any error: ROLLBACK, then close the connection (temporary table cleanup).
-- Each section is standalone; all persistent fixture/change rows are rolled back.

-- BEGIN E3: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E3 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Late contract entered ten days after January 31');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E3');

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-31', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-31' AND valid_to = '9999-12-31' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: late by ten days and absent before recording', COALESCE((DATEDIFF(@t, '2025-01-31') = 10 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to) = 0), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E3') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E4: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E4 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Correct erroneous salary from inception');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E4');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1500, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1500 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E4') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E5: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E5 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Player really left on February 1');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E5');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '2025-02-01', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '2025-02-01' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: real tenure remains; departure boundary excluded', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf AND valid_from <= '2025-01-31' AND '2025-01-31' < valid_to) = 1 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf AND valid_from <= '2025-02-01' AND '2025-02-01' < valid_to) = 0), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E5') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E8: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E8 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Retract contract that never existed');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E8');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: no replacement; past tenure also retracted', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id) = 1 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 0 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_id = @write_tx_id) = 0), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E8') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E9: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E9 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'One decision adjusts contract salary and club budget');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E9');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

UPDATE club_version SET tx_to = @t
WHERE version_id = @old_club_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: exactly one old club closed', COALESCE((@closed_count = 1), 0);

INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1200000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1500, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1500 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: same tx_id and timestamp in two tables', COALESCE(((SELECT COUNT(*) FROM contract_version c JOIN club_version b ON b.tx_id = c.tx_id AND b.tx_from = c.tx_from JOIN tx_registry r ON r.tx_id = c.tx_id AND r.tx_time = c.tx_from WHERE c.version_id = @new_version_id AND b.version_id = @new_club_version_id AND c.tx_id = @write_tx_id AND c.tx_from = @t AND c.salary_eur = 1500 AND b.budget_eur = 1200000 AND c.tx_to = @inf AND b.tx_to = @inf) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: old budget preserved', COALESCE(((SELECT COUNT(*) FROM club_version WHERE version_id = @old_club_version_id AND budget_eur = 1000000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E9') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;
