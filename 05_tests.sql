-- Part C entry point; standalone MariaDB CLI, DELIMITER aware. Fresh session required.
-- Default: only query_params is changed and restored. Negative fixtures require both gates.
SET
NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SET
time_zone = '+00:00';

DELIMITER $$
BEGIN
	NOT ATOMIC
 DECLARE sv DATE;

DECLARE sk DATETIME(6);

DECLARE ss DATE;

DECLARE se DATE;

DECLARE sid BIGINT UNSIGNED;

DECLARE saved BOOLEAN DEFAULT FALSE;

DECLARE checks INT DEFAULT 0;

DECLARE scenario VARCHAR(128) DEFAULT 'preflight';

DECLARE err TEXT;

DECLARE eno INT;

DECLARE xclub BIGINT UNSIGNED;

DECLARE xcontract BIGINT UNSIGNED;

DECLARE xrole BIGINT UNSIGNED;

DECLARE xtx BIGINT UNSIGNED;

DECLARE xv BIGINT UNSIGNED;

DECLARE xv2 BIGINT UNSIGNED;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
	GET DIAGNOSTICS CONDITION 1 eno = MYSQL_ERRNO,
	err = MESSAGE_TEXT;

ROLLBACK;

IF saved THEN
UPDATE
	query_params
SET
	valid_at = sv,
	known_at = sk,
	period_start = ss,
	period_end = se,
	subject_id = sid
WHERE
	params_id = 1;
END IF;

SET
@sim_now = NULL,
@write_tx_id = NULL;

SELECT
	scenario AS failed_scenario,
	eno AS error_code,
	err AS error_message;

RESIGNAL;
END;

IF @@in_transaction THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_SESSION: fresh session required';
END IF;

IF COALESCE(@p3_negative, 0)<> 0
AND (COALESCE(@p3_negative, 0)<> 1
	OR DATABASE()= 'two_clocks_cabd'
	OR DATABASE() NOT REGEXP '^two_clocks_cabd_verify_p3_[a-zA-Z0-9_]+$'
	OR NOT (BINARY DATABASE() <=> BINARY @p3_test_database)) THEN
 SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_GUARD: negative fixtures require runner-created matching test database';
END IF;

IF (
SELECT
	COUNT(*)
FROM
	query_params)<> 1 THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_PARAMS: singleton missing';
END IF;

SELECT
	valid_at,
	known_at,
	period_start,
	period_end,
	subject_id
INTO
	sv,
	sk,
	ss,
	se,
	sid
FROM
	query_params
WHERE
	params_id = 1;

SET
saved = TRUE;

IF (
SELECT
	COUNT(*)
FROM
	tx_registry)<>(
SELECT
	COUNT(DISTINCT tx_time)
FROM
	tx_registry) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_AUDIT: ambiguous closing times';
END IF;

SET
scenario = 'Q0_clean';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('0');

INSERT
	INTO
	p3_actual
SELECT
	COUNT(*) AS c1
FROM
	v_integrity_violations;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q0_clean' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	COUNT(*) AS violation_count
FROM
	v_integrity_violations;

SELECT
	*
FROM
	v_integrity_violations
ORDER BY
	invariant_code,
	source_table,
	business_key,
	version_id;

SELECT
	'P3_RESULT_END:Q0_clean' AS p3_marker;

SET
scenario = 'Q1_today_P006';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P006')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
SELECT
	*
FROM
	(
	SELECT
		'P006' AS c1,
		'CL01' AS c2,
		'PERMANENT' AS c3,
		'1060.00' AS c4,
		'2025-07-01' AS c5,
		'9999-12-31' AS c6,
		'2025-07-01 09:00:00.000000' AS c7,
		'9999-12-31 23:59:59.999999' AS c8
UNION ALL
	SELECT
		'P006' AS c1,
		'CL02' AS c2,
		'LOAN' AS c3,
		'600.00' AS c4,
		'2026-06-01' AS c5,
		'2026-07-01' AS c6,
		'2026-07-05 10:00:00.000000' AS c7,
		'9999-12-31 23:59:59.999999' AS c8
UNION ALL
	SELECT
		'P006' AS c1,
		'CL02' AS c2,
		'LOAN' AS c3,
		'650.00' AS c4,
		'2026-10-01' AS c5,
		'2026-12-01' AS c6,
		'2026-09-20 10:00:00.000000' AS c7,
		'9999-12-31 23:59:59.999999' AS c8) literals
WHERE
	c5 <= UTC_DATE()
	AND UTC_DATE()<c6
ORDER BY
	c2,
	c5;

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8
FROM
	v_q1_current_contracts
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q1_today_P006' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q1_current_contracts
ORDER BY
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q1_today_P006' AS p3_marker;

SET
scenario = 'Q2_today_CL01';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
SELECT
	'CL01' AS c1,
	'H01' AS c2,
	'2025-07-01' AS c3,
	'2026-03-03' AS c4,
	'245' AS c5,
	GREATEST(DATEDIFF(LEAST(UTC_DATE(), '2026-03-03'), '2025-07-01'), 0) AS c6,
	CASE
		WHEN UTC_DATE()<'2025-07-01' THEN 'SCHEDULED'
		WHEN UTC_DATE()>= '2026-03-03' THEN 'ENDED'
		ELSE 'ACTIVE'
	END AS c7
UNION ALL
SELECT
	'CL01' AS c1,
	'H02' AS c2,
	'2026-03-03' AS c3,
	'9999-12-31' AS c4,
	NULL AS c5,
	GREATEST(DATEDIFF(LEAST(UTC_DATE(), '9999-12-31'), '2026-03-03'), 0) AS c6,
	CASE
		WHEN UTC_DATE()<'2026-03-03' THEN 'SCHEDULED'
		WHEN UTC_DATE()>= '9999-12-31' THEN 'ENDED'
		ELSE 'ACTIVE'
	END AS c7;

INSERT
	INTO
	p3_actual
SELECT
	club_code AS c1,
	coach_code AS c2,
	tenure_from AS c3,
	tenure_to AS c4,
	tenure_days AS c5,
	elapsed_days AS c6,
	tenure_status AS c7
FROM
	v_q2_coach_tenures
ORDER BY
	tenure_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q2_today_CL01' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q2_coach_tenures
ORDER BY
	tenure_from,
	coach_code;

SELECT
	'P3_RESULT_END:Q2_today_CL01' AS p3_marker;

SET
scenario = 'Q2_today_CL03';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL03')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
SELECT
	'CL03' AS c1,
	'H04' AS c2,
	'2025-07-01' AS c3,
	'2026-10-01' AS c4,
	'457' AS c5,
	GREATEST(DATEDIFF(LEAST(UTC_DATE(), '2026-10-01'), '2025-07-01'), 0) AS c6,
	CASE
		WHEN UTC_DATE()<'2025-07-01' THEN 'SCHEDULED'
		WHEN UTC_DATE()>= '2026-10-01' THEN 'ENDED'
		ELSE 'ACTIVE'
	END AS c7
UNION ALL
SELECT
	'CL03' AS c1,
	'H01' AS c2,
	'2026-10-01' AS c3,
	'9999-12-31' AS c4,
	NULL AS c5,
	GREATEST(DATEDIFF(LEAST(UTC_DATE(), '9999-12-31'), '2026-10-01'), 0) AS c6,
	CASE
		WHEN UTC_DATE()<'2026-10-01' THEN 'SCHEDULED'
		WHEN UTC_DATE()>= '9999-12-31' THEN 'ENDED'
		ELSE 'ACTIVE'
	END AS c7;

INSERT
	INTO
	p3_actual
SELECT
	club_code AS c1,
	coach_code AS c2,
	tenure_from AS c3,
	tenure_to AS c4,
	tenure_days AS c5,
	elapsed_days AS c6,
	tenure_status AS c7
FROM
	v_q2_coach_tenures
ORDER BY
	tenure_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q2_today_CL03' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q2_coach_tenures
ORDER BY
	tenure_from,
	coach_code;

SELECT
	'P3_RESULT_END:Q2_today_CL03' AS p3_marker;

SET
scenario = 'Q2_today_CL04';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL04')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
SELECT
	'CL04' AS c1,
	'H05' AS c2,
	'2025-07-01' AS c3,
	'9999-12-31' AS c4,
	NULL AS c5,
	GREATEST(DATEDIFF(LEAST(UTC_DATE(), '9999-12-31'), '2025-07-01'), 0) AS c6,
	CASE
		WHEN UTC_DATE()<'2025-07-01' THEN 'SCHEDULED'
		WHEN UTC_DATE()>= '9999-12-31' THEN 'ENDED'
		ELSE 'ACTIVE'
	END AS c7;

INSERT
	INTO
	p3_actual
SELECT
	club_code AS c1,
	coach_code AS c2,
	tenure_from AS c3,
	tenure_to AS c4,
	tenure_days AS c5,
	elapsed_days AS c6,
	tenure_status AS c7
FROM
	v_q2_coach_tenures
ORDER BY
	tenure_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q2_today_CL04' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q2_coach_tenures
ORDER BY
	tenure_from,
	coach_code;

SELECT
	'P3_RESULT_END:Q2_today_CL04' AS p3_marker;

SET
scenario = 'Q3_all_events';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci,
c10 LONGTEXT COLLATE utf8mb4_unicode_ci,
c11 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('T02',
'CONTRACT',
'P001',
'2025-09-10 14:00:00.000000',
'E3',
'0',
'1',
'0',
'2025-08-31',
'10',
'0'),
('T03',
'CONTRACT',
'P002',
'2025-09-15 14:00:00.000000',
'E3',
'0',
'1',
'0',
'2025-08-30',
'16',
'0'),
('T04',
'CONTRACT',
'P003',
'2025-09-22 14:00:00.000000',
'E3',
'0',
'1',
'0',
'2025-08-29',
'24',
'0'),
('T05',
'CLUB',
'CL01',
'2025-10-05 10:00:00.000000',
'E2',
'1',
'0',
'0',
'2025-11-01',
'-27',
'27'),
('T06',
'CONTRACT',
'P004',
'2025-10-12 14:00:00.000000',
'E3',
'0',
'1',
'0',
'2025-08-28',
'45',
'0'),
('T07',
'CONTRACT',
'P005',
'2025-10-20 14:00:00.000000',
'E3',
'0',
'1',
'0',
'2025-08-27',
'54',
'0'),
('T08',
'CLUB',
'CL02',
'2025-11-10 10:00:00.000000',
'E2',
'1',
'0',
'0',
'2025-12-01',
'-21',
'21'),
('T09',
'CLUB',
'CL03',
'2025-12-01 10:00:00.000000',
'E2',
'1',
'0',
'0',
'2026-01-01',
'-31',
'31'),
('T13',
'CONTRACT',
'P016',
'2026-01-08 14:00:00.000000',
'E3,E5',
'0',
'1',
'0',
'2026-01-01',
'7',
'0'),
('T15',
'CONTRACT',
'P013',
'2026-01-20 10:00:00.000000',
'E2,E6',
'1',
'0',
'0',
'2026-02-01',
'-12',
'12'),
('T16',
'HEAD_COACH',
'CL02',
'2026-01-20 14:00:00.000000',
'E3,E7',
'0',
'1',
'0',
'2026-01-10',
'10',
'0'),
('T17',
'CONTRACT',
'P014',
'2026-02-15 10:00:00.000000',
'E2,E6',
'1',
'0',
'0',
'2026-03-01',
'-14',
'14'),
('T18',
'HEAD_COACH',
'CL01',
'2026-03-10 14:00:00.000000',
'E3,E7',
'0',
'1',
'0',
'2026-03-01',
'9',
'0'),
('T19',
'HEAD_COACH',
'CL01',
'2026-03-15 11:00:00.000000',
'E3,E4',
'0',
'1',
'1',
'2026-03-03',
'12',
'0'),
('T20',
'CONTRACT',
'P015',
'2026-03-20 14:00:00.000000',
'E3,E6',
'0',
'1',
'0',
'2026-03-10',
'10',
'0'),
('T21',
'CONTRACT',
'P060',
'2026-04-10 14:00:00.000000',
'E3',
'0',
'1',
'0',
'2026-04-01',
'9',
'0'),
('T22',
'CONTRACT',
'P025',
'2026-04-15 10:00:00.000000',
'E2',
'1',
'0',
'0',
'2026-05-01',
'-16',
'16'),
('T23',
'CONTRACT',
'P026',
'2026-04-20 10:00:00.000000',
'E3,E4',
'0',
'1',
'1',
'2025-07-01',
'293',
'0'),
('T24',
'CONTRACT',
'P027',
'2026-04-22 10:00:00.000000',
'E3,E4',
'0',
'1',
'1',
'2025-07-01',
'295',
'0'),
('T26',
'CONTRACT',
'P025',
'2026-05-10 10:00:00.000000',
'E3,E4',
'0',
'1',
'1',
'2026-05-01',
'9',
'0'),
('T27',
'CONTRACT',
'P026',
'2026-05-15 10:00:00.000000',
'E2',
'1',
'0',
'0',
'2026-06-01',
'-17',
'17'),
('T28',
'CONTRACT',
'P006',
'2026-06-10 10:00:00.000000',
'E3',
'0',
'1',
'0',
'2026-06-01',
'9',
'0'),
('T29',
'CONTRACT',
'P007',
'2026-06-10 11:00:00.000000',
'E3',
'0',
'1',
'0',
'2026-06-01',
'9',
'0'),
('T30',
'CONTRACT',
'P008',
'2026-06-10 12:00:00.000000',
'E3',
'0',
'1',
'0',
'2026-06-01',
'9',
'0'),
('T31',
'CONTRACT',
'P027',
'2026-06-15 10:00:00.000000',
'E2',
'1',
'0',
'0',
'2026-07-01',
'-16',
'16'),
('T33',
'CONTRACT',
'P027',
'2026-07-10 10:00:00.000000',
'E3,E4',
'0',
'1',
'1',
'2026-07-01',
'9',
'0'),
('T34',
'CLUB',
'CL04',
'2026-07-15 10:00:00.000000',
'E2,E9',
'1',
'0',
'0',
'2026-08-01',
'-17',
'17'),
('T34',
'CONTRACT',
'P037',
'2026-07-15 10:00:00.000000',
'E2,E9',
'1',
'0',
'0',
'2026-08-01',
'-17',
'17'),
('T35',
'CLUB',
'CL05',
'2026-08-15 10:00:00.000000',
'E2,E9',
'1',
'0',
'0',
'2026-09-01',
'-17',
'17'),
('T35',
'CONTRACT',
'P049',
'2026-08-15 10:00:00.000000',
'E2,E9',
'1',
'0',
'0',
'2026-09-01',
'-17',
'17'),
('T36',
'HEAD_COACH',
'CL03',
'2026-09-01 10:00:00.000000',
'E2,E7',
'1',
'0',
'0',
'2026-10-01',
'-30',
'30'),
('T37',
'CLUB',
'CL06',
'2026-09-10 10:00:00.000000',
'E2',
'1',
'0',
'0',
'2026-11-01',
'-52',
'52'),
('T38',
'CONTRACT',
'P006',
'2026-09-20 10:00:00.000000',
'E2,E6',
'1',
'0',
'0',
'2026-10-01',
'-11',
'11');

INSERT
	INTO
	p3_actual
SELECT
	event_ref AS c1,
	fact_family AS c2,
	subject_code AS c3,
	DATE_FORMAT(tx_time, '%Y-%m-%d %H:%i:%s.%f') AS c4,
	event_codes AS c5,
	is_proactive AS c6,
	is_late AS c7,
	is_correction AS c8,
	effective_date AS c9,
	delay_days AS c10,
	lead_days AS c11
FROM
	v_q3_event_audit
ORDER BY
	event_ref,
	fact_family,
	subject_code;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9) AND (BINARY a.c10 <=> BINARY e.c10) AND (BINARY a.c11 <=> BINARY e.c11))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q3_all_events' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q3_event_audit
ORDER BY
	tx_time,
	fact_family,
	subject_code;

SELECT
	'P3_RESULT_END:Q3_all_events' AS p3_marker;

SET
scenario = 'Q3_distinct_counts';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('33',
'31',
'13',
'18',
'5');

INSERT
	INTO
	p3_actual
SELECT
	COUNT(*) AS c1,
	COUNT(DISTINCT tx_id) AS c2,
	COUNT(DISTINCT CASE WHEN is_proactive = 1 THEN tx_id END) AS c3,
	COUNT(DISTINCT CASE WHEN is_late = 1 THEN tx_id END) AS c4,
	COUNT(DISTINCT CASE WHEN is_correction = 1 THEN tx_id END) AS c5
FROM
	v_q3_event_audit;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q3_distinct_counts' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	COUNT(*) AS c1,
	COUNT(DISTINCT tx_id) AS c2,
	COUNT(DISTINCT CASE WHEN is_proactive = 1 THEN tx_id END) AS c3,
	COUNT(DISTINCT CASE WHEN is_late = 1 THEN tx_id END) AS c4,
	COUNT(DISTINCT CASE WHEN is_correction = 1 THEN tx_id END) AS c5
FROM
	v_q3_event_audit;

SELECT
	'P3_RESULT_END:Q3_distinct_counts' AS p3_marker;

SET
scenario = 'Q3_unique_registry_times';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('38',
'38');

INSERT
	INTO
	p3_actual
SELECT
	COUNT(*) AS c1,
	COUNT(DISTINCT tx_time) AS c2
FROM
	tx_registry;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q3_unique_registry_times' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	COUNT(*) AS c1,
	COUNT(DISTINCT tx_time) AS c2
FROM
	tx_registry;

SELECT
	'P3_RESULT_END:Q3_unique_registry_times' AS p3_marker;

SET
scenario = 'Q4_season1';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci,
c10 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL02',
'LOAN',
'600.00',
'2026-06-01',
'2026-07-01',
'2026-07-05 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P006',
'CL02',
'LOAN',
'650.00',
'2026-10-01',
'2026-12-01',
'2026-09-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P007',
'CL03',
'LOAN',
'700.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 11:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P008',
'CL04',
'LOAN',
'800.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 12:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P025',
'CL03',
'PERMANENT',
'1455.00',
'2026-05-01',
'9999-12-31',
'2026-05-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'2026-06-01',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P026',
'CL03',
'PERMANENT',
'1480.00',
'2026-06-01',
'9999-12-31',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'2026-07-01',
'2026-06-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P027',
'CL03',
'PERMANENT',
'1495.00',
'2026-07-01',
'9999-12-31',
'2026-07-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'2026-08-01',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P037',
'CL04',
'PERMANENT',
'1570.00',
'2026-08-01',
'9999-12-31',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'2026-09-01',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P049',
'CL05',
'PERMANENT',
'1740.00',
'2026-09-01',
'9999-12-31',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	at_some_point AS c9,
	throughout AS c10
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9) AND (BINARY a.c10 <=> BINARY e.c10))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q4_season1' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q4_season1' AS p3_marker;

SET
scenario = 'Q4_season2';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2026-07-01',
	period_end = '2027-07-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci,
c10 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL02',
'LOAN',
'600.00',
'2026-06-01',
'2026-07-01',
'2026-07-05 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P006',
'CL02',
'LOAN',
'650.00',
'2026-10-01',
'2026-12-01',
'2026-09-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P007',
'CL03',
'LOAN',
'700.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 11:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P008',
'CL04',
'LOAN',
'800.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 12:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P025',
'CL03',
'PERMANENT',
'1455.00',
'2026-05-01',
'9999-12-31',
'2026-05-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'2026-06-01',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P026',
'CL03',
'PERMANENT',
'1480.00',
'2026-06-01',
'9999-12-31',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'2026-07-01',
'2026-06-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P027',
'CL03',
'PERMANENT',
'1495.00',
'2026-07-01',
'9999-12-31',
'2026-07-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'2026-08-01',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P037',
'CL04',
'PERMANENT',
'1570.00',
'2026-08-01',
'9999-12-31',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'2026-09-01',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P049',
'CL05',
'PERMANENT',
'1740.00',
'2026-09-01',
'9999-12-31',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	at_some_point AS c9,
	throughout AS c10
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9) AND (BINARY a.c10 <=> BINARY e.c10))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q4_season2' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q4_season2' AS p3_marker;

SET
scenario = 'Q4_exact_loan';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2026-06-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci,
c10 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL02',
'LOAN',
'600.00',
'2026-06-01',
'2026-07-01',
'2026-07-05 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL02',
'LOAN',
'650.00',
'2026-10-01',
'2026-12-01',
'2026-09-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P007',
'CL03',
'LOAN',
'700.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 11:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P008',
'CL04',
'LOAN',
'800.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 12:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P025',
'CL03',
'PERMANENT',
'1455.00',
'2026-05-01',
'9999-12-31',
'2026-05-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'2026-06-01',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P026',
'CL03',
'PERMANENT',
'1480.00',
'2026-06-01',
'9999-12-31',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'2026-07-01',
'2026-06-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P027',
'CL03',
'PERMANENT',
'1495.00',
'2026-07-01',
'9999-12-31',
'2026-07-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'2026-08-01',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P037',
'CL04',
'PERMANENT',
'1570.00',
'2026-08-01',
'9999-12-31',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'2026-09-01',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P049',
'CL05',
'PERMANENT',
'1740.00',
'2026-09-01',
'9999-12-31',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	at_some_point AS c9,
	throughout AS c10
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9) AND (BINARY a.c10 <=> BINARY e.c10))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q4_exact_loan' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q4_exact_loan' AS p3_marker;

SET
scenario = 'Q4_touch_loan';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2026-07-01',
	period_end = '2026-10-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci,
c10 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P006',
'CL02',
'LOAN',
'600.00',
'2026-06-01',
'2026-07-01',
'2026-07-05 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P006',
'CL02',
'LOAN',
'650.00',
'2026-10-01',
'2026-12-01',
'2026-09-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P007',
'CL03',
'LOAN',
'700.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 11:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P008',
'CL04',
'LOAN',
'800.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 12:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P025',
'CL03',
'PERMANENT',
'1455.00',
'2026-05-01',
'9999-12-31',
'2026-05-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'2026-06-01',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P026',
'CL03',
'PERMANENT',
'1480.00',
'2026-06-01',
'9999-12-31',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'2026-07-01',
'2026-06-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'0',
'0'),
('P027',
'CL03',
'PERMANENT',
'1495.00',
'2026-07-01',
'9999-12-31',
'2026-07-10 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'2026-08-01',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P037',
'CL04',
'PERMANENT',
'1570.00',
'2026-08-01',
'9999-12-31',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'2026-09-01',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P049',
'CL05',
'PERMANENT',
'1740.00',
'2026-09-01',
'9999-12-31',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'0'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999',
'1',
'1');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	at_some_point AS c9,
	throughout AS c10
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9) AND (BINARY a.c10 <=> BINARY e.c10))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q4_touch_loan' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q4_period_relationships
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q4_touch_loan' AS p3_marker;

SET
scenario = 'Q5_final';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL02',
'LOAN',
'600.00',
'2026-06-01',
'2026-07-01',
'2026-07-05 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL02',
'LOAN',
'650.00',
'2026-10-01',
'2026-12-01',
'2026-09-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL03',
'LOAN',
'700.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 11:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL04',
'LOAN',
'800.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 12:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1455.00',
'2026-05-01',
'9999-12-31',
'2026-05-10 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'2026-06-01',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P026',
'CL03',
'PERMANENT',
'1480.00',
'2026-06-01',
'9999-12-31',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'2026-07-01',
'2026-06-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P027',
'CL03',
'PERMANENT',
'1495.00',
'2026-07-01',
'9999-12-31',
'2026-07-10 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'2026-08-01',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1570.00',
'2026-08-01',
'9999-12-31',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'2026-09-01',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1740.00',
'2026-09-01',
'9999-12-31',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q5_final' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q5_final' AS p3_marker;

SET
scenario = 'Q5_ignore_valid_subject';

UPDATE
	query_params
SET
	valid_at = '1900-01-01',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL06')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL02',
'LOAN',
'600.00',
'2026-06-01',
'2026-07-01',
'2026-07-05 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL02',
'LOAN',
'650.00',
'2026-10-01',
'2026-12-01',
'2026-09-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL03',
'LOAN',
'700.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 11:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL04',
'LOAN',
'800.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 12:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1455.00',
'2026-05-01',
'9999-12-31',
'2026-05-10 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'2026-06-01',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P026',
'CL03',
'PERMANENT',
'1480.00',
'2026-06-01',
'9999-12-31',
'2026-05-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'2026-07-01',
'2026-06-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P027',
'CL03',
'PERMANENT',
'1495.00',
'2026-07-01',
'9999-12-31',
'2026-07-10 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'2026-08-01',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1570.00',
'2026-08-01',
'9999-12-31',
'2026-07-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'2026-09-01',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1740.00',
'2026-09-01',
'9999-12-31',
'2026-08-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q5_ignore_valid_subject' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q5_ignore_valid_subject' AS p3_marker;

SET
scenario = 'Q5_before_T21';

UPDATE
	query_params
SET
	valid_at = '2026-04-15',
	known_at = '2026-04-10 13:59:59.999999',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-04-15 10:00:00.000000'),
('P026',
'CL03',
'PERMANENT',
'1260.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-04-20 10:00:00.000000'),
('P027',
'CL03',
'PERMANENT',
'1270.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-04-22 10:00:00.000000'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-07-15 10:00:00.000000'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-08-15 10:00:00.000000'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q5_before_T21' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q5_before_T21' AS p3_marker;

SET
scenario = 'Q5_at_T21';

UPDATE
	query_params
SET
	valid_at = '2026-04-15',
	known_at = '2026-04-10 14:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-04-15 10:00:00.000000'),
('P026',
'CL03',
'PERMANENT',
'1260.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-04-20 10:00:00.000000'),
('P027',
'CL03',
'PERMANENT',
'1270.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-04-22 10:00:00.000000'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-07-15 10:00:00.000000'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-08-15 10:00:00.000000'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL06',
'LOAN',
'600.00',
'2026-04-01',
'2026-05-01',
'2026-04-10 14:00:00.000000',
'2026-04-25 10:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q5_at_T21' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q5_at_T21' AS p3_marker;

SET
scenario = 'Q5_before_T25';

UPDATE
	query_params
SET
	valid_at = '2026-04-15',
	known_at = '2026-04-25 09:59:59.999999',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1450.00',
'2026-05-01',
'9999-12-31',
'2026-04-15 10:00:00.000000',
'2026-05-10 10:00:00.000000'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2026-04-20 10:00:00.000000',
'2026-05-15 10:00:00.000000'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2026-04-22 10:00:00.000000',
'2026-06-15 10:00:00.000000'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-07-15 10:00:00.000000'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-08-15 10:00:00.000000'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL06',
'LOAN',
'600.00',
'2026-04-01',
'2026-05-01',
'2026-04-10 14:00:00.000000',
'2026-04-25 10:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q5_before_T25' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q5_before_T25' AS p3_marker;

SET
scenario = 'Q5_at_T25';

UPDATE
	query_params
SET
	valid_at = '2026-04-15',
	known_at = '2026-04-25 10:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P001',
'CL01',
'PERMANENT',
'1010.00',
'2025-07-01',
'2025-08-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P001',
'CL06',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL01',
'PERMANENT',
'1020.00',
'2025-07-01',
'2025-08-30',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P002',
'CL02',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL01',
'PERMANENT',
'1030.00',
'2025-07-01',
'2025-08-29',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P003',
'CL03',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL01',
'PERMANENT',
'1040.00',
'2025-07-01',
'2025-08-28',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P004',
'CL04',
'PERMANENT',
'1540.00',
'2025-08-28',
'9999-12-31',
'2025-10-12 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL01',
'PERMANENT',
'1050.00',
'2025-07-01',
'2025-08-27',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P005',
'CL05',
'PERMANENT',
'1550.00',
'2025-08-27',
'9999-12-31',
'2025-10-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P006',
'CL01',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P007',
'CL01',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P008',
'CL01',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P009',
'CL01',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P010',
'CL01',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P011',
'CL01',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P012',
'CL01',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2025-07-01',
'2025-12-01',
'2025-12-03 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P013',
'CL02',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2025-07-01',
'2025-12-15',
'2025-12-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P014',
'CL02',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2025-07-01',
'2025-12-20',
'2025-12-23 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P015',
'CL02',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P016',
'CL02',
'PERMANENT',
'1160.00',
'2025-07-01',
'2026-01-01',
'2026-01-08 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P017',
'CL02',
'PERMANENT',
'1170.00',
'2025-07-01',
'2026-01-15',
'2026-01-18 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P018',
'CL02',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P019',
'CL02',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P020',
'CL02',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P021',
'CL02',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P022',
'CL02',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P023',
'CL02',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P024',
'CL02',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1250.00',
'2025-07-01',
'2026-05-01',
'2026-04-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P025',
'CL03',
'PERMANENT',
'1450.00',
'2026-05-01',
'9999-12-31',
'2026-04-15 10:00:00.000000',
'2026-05-10 10:00:00.000000'),
('P026',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2026-04-20 10:00:00.000000',
'2026-05-15 10:00:00.000000'),
('P027',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2026-04-22 10:00:00.000000',
'2026-06-15 10:00:00.000000'),
('P028',
'CL03',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P029',
'CL03',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P030',
'CL03',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P031',
'CL03',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P032',
'CL03',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P033',
'CL03',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P034',
'CL03',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P035',
'CL03',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P036',
'CL03',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P037',
'CL04',
'PERMANENT',
'1370.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-07-15 10:00:00.000000'),
('P038',
'CL04',
'PERMANENT',
'1380.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P039',
'CL04',
'PERMANENT',
'1390.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P040',
'CL04',
'PERMANENT',
'1400.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P041',
'CL04',
'PERMANENT',
'1410.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P042',
'CL04',
'PERMANENT',
'1420.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P043',
'CL04',
'PERMANENT',
'1430.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P044',
'CL04',
'PERMANENT',
'1440.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P045',
'CL04',
'PERMANENT',
'1450.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P046',
'CL04',
'PERMANENT',
'1460.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P047',
'CL04',
'PERMANENT',
'1470.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P048',
'CL04',
'PERMANENT',
'1480.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P049',
'CL05',
'PERMANENT',
'1490.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-08-15 10:00:00.000000'),
('P050',
'CL05',
'PERMANENT',
'1500.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P051',
'CL05',
'PERMANENT',
'1510.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P052',
'CL05',
'PERMANENT',
'1520.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P053',
'CL05',
'PERMANENT',
'1530.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P054',
'CL05',
'PERMANENT',
'1540.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P055',
'CL05',
'PERMANENT',
'1550.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P056',
'CL05',
'PERMANENT',
'1560.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P057',
'CL05',
'PERMANENT',
'1570.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P058',
'CL05',
'PERMANENT',
'1580.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P059',
'CL05',
'PERMANENT',
'1590.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('P060',
'CL05',
'PERMANENT',
'1600.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	agreement_kind AS c3,
	salary_eur AS c4,
	valid_from AS c5,
	valid_to AS c6,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c7,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c8
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q5_at_T25' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q5_contracts_as_known
ORDER BY
	player_code,
	club_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q5_at_T25' AS p3_marker;

SET
scenario = 'Q6_perspective_1';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-05 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-03-10 14:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_perspective_1' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_perspective_1' AS p3_marker;

SET
scenario = 'Q6_perspective_2';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_perspective_2' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_perspective_2' AS p3_marker;

SET
scenario = 'Q6_perspective_3';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-16 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'2026-03-03',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_perspective_3' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_perspective_3' AS p3_marker;

SET
scenario = 'Q6_T18_before';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-10 13:59:59.999999',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-03-10 14:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_T18_before' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_T18_before' AS p3_marker;

SET
scenario = 'Q6_T18_exact';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-10 14:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_T18_exact' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_T18_exact' AS p3_marker;

SET
scenario = 'Q6_T18_after';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-10 14:00:00.000001',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_T18_after' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_T18_after' AS p3_marker;

SET
scenario = 'Q6_T19_before';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-15 10:59:59.999999',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_T19_before' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_T19_before' AS p3_marker;

SET
scenario = 'Q6_T19_exact';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-15 11:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'2026-03-03',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_T19_exact' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_T19_exact' AS p3_marker;

SET
scenario = 'Q6_T19_after';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-15 11:00:00.000001',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'2026-03-03',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_T19_after' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_T19_after' AS p3_marker;

SET
scenario = 'Q6_VT_2026-02-28_initial';

UPDATE
	query_params
SET
	valid_at = '2026-02-28',
	known_at = '2026-03-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'2026-03-01',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-02-28_initial' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-02-28_initial' AS p3_marker;

SET
scenario = 'Q6_VT_2026-02-28_corrected';

UPDATE
	query_params
SET
	valid_at = '2026-02-28',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'2026-03-03',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-02-28_corrected' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-02-28_corrected' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-01_initial';

UPDATE
	query_params
SET
	valid_at = '2026-03-01',
	known_at = '2026-03-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-01_initial' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-01_initial' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-01_corrected';

UPDATE
	query_params
SET
	valid_at = '2026-03-01',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'2026-03-03',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-01_corrected' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-01_corrected' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-02_initial';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-03-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-02_initial' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-02_initial' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-02_corrected';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'2026-03-03',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-02_corrected' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-02_corrected' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-03_initial';

UPDATE
	query_params
SET
	valid_at = '2026-03-03',
	known_at = '2026-03-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-03_initial' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-03_initial' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-03_corrected';

UPDATE
	query_params
SET
	valid_at = '2026-03-03',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-03',
'9999-12-31',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-03_corrected' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-03_corrected' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-04_initial';

UPDATE
	query_params
SET
	valid_at = '2026-03-04',
	known_at = '2026-03-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-01',
'9999-12-31',
'2026-03-10 14:00:00.000000',
'2026-03-15 11:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-04_initial' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-04_initial' AS p3_marker;

SET
scenario = 'Q6_VT_2026-03-04_corrected';

UPDATE
	query_params
SET
	valid_at = '2026-03-04',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H02',
NULL,
NULL,
'2026-03-03',
'9999-12-31',
'2026-03-15 11:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_VT_2026-03-04_corrected' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_VT_2026-03-04_corrected' AS p3_marker;

SET
scenario = 'Q6_transfer_old';

UPDATE
	query_params
SET
	valid_at = '2025-09-01',
	known_at = '2025-09-05 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL01',
'P001',
'PERMANENT',
'1010.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2025-09-10 14:00:00.000000'),
('CONTRACT',
'CL01',
'P002',
'PERMANENT',
'1020.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2025-09-15 14:00:00.000000'),
('CONTRACT',
'CL01',
'P003',
'PERMANENT',
'1030.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2025-09-22 14:00:00.000000'),
('CONTRACT',
'CL01',
'P004',
'PERMANENT',
'1040.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2025-10-12 14:00:00.000000'),
('CONTRACT',
'CL01',
'P005',
'PERMANENT',
'1050.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2025-10-20 14:00:00.000000'),
('CONTRACT',
'CL01',
'P006',
'PERMANENT',
'1060.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P007',
'PERMANENT',
'1070.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P008',
'PERMANENT',
'1080.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P009',
'PERMANENT',
'1090.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P010',
'PERMANENT',
'1100.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P011',
'PERMANENT',
'1110.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL01',
'P012',
'PERMANENT',
'1120.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL01',
'H01',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-03-10 14:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_transfer_old' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_transfer_old' AS p3_marker;

SET
scenario = 'Q6_transfer_new';

UPDATE
	query_params
SET
	valid_at = '2025-09-01',
	known_at = '2025-09-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL06')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL06',
'P001',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL06',
'H07',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_transfer_new' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_transfer_new' AS p3_marker;

SET
scenario = 'Q6_transfer_boundary';

UPDATE
	query_params
SET
	valid_at = '2025-08-31',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL06')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL06',
'P001',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL06',
'H07',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_transfer_boundary' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_transfer_boundary' AS p3_marker;

SET
scenario = 'Q6_loan_before';

UPDATE
	query_params
SET
	valid_at = '2026-07-15',
	known_at = '2026-06-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL02')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL02',
'P002',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P006',
'LOAN',
'600.00',
'2026-06-01',
'2026-09-01',
'2026-06-10 10:00:00.000000',
'2026-07-05 10:00:00.000000'),
('CONTRACT',
'CL02',
'P013',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P014',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P015',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P018',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P019',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P020',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P021',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P022',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P023',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P024',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL02',
'H08',
NULL,
NULL,
'2026-01-10',
'9999-12-31',
'2026-01-20 14:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_loan_before' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_loan_before' AS p3_marker;

SET
scenario = 'Q6_loan_after';

UPDATE
	query_params
SET
	valid_at = '2026-07-15',
	known_at = '2026-07-06 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL02')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL02',
'P002',
'PERMANENT',
'1520.00',
'2025-08-30',
'9999-12-31',
'2025-09-15 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P013',
'PERMANENT',
'1130.00',
'2026-02-01',
'9999-12-31',
'2026-01-20 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P014',
'PERMANENT',
'1140.00',
'2026-03-01',
'9999-12-31',
'2026-02-15 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P015',
'PERMANENT',
'1150.00',
'2026-03-10',
'9999-12-31',
'2026-03-20 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P018',
'PERMANENT',
'1180.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P019',
'PERMANENT',
'1190.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P020',
'PERMANENT',
'1200.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P021',
'PERMANENT',
'1210.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P022',
'PERMANENT',
'1220.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P023',
'PERMANENT',
'1230.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL02',
'P024',
'PERMANENT',
'1240.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL02',
'H08',
NULL,
NULL,
'2026-01-10',
'9999-12-31',
'2026-01-20 14:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_loan_after' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_loan_after' AS p3_marker;

SET
scenario = 'Q6_retract_before';

UPDATE
	query_params
SET
	valid_at = '2026-04-15',
	known_at = '2026-04-12 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL06')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL06',
'P001',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL06',
'P060',
'LOAN',
'600.00',
'2026-04-01',
'2026-05-01',
'2026-04-10 14:00:00.000000',
'2026-04-25 10:00:00.000000'),
('HEAD_COACH',
'CL06',
'H07',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_retract_before' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_retract_before' AS p3_marker;

SET
scenario = 'Q6_retract_after';

UPDATE
	query_params
SET
	valid_at = '2026-04-15',
	known_at = '2026-04-26 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL06')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL06',
'P001',
'PERMANENT',
'1510.00',
'2025-08-31',
'9999-12-31',
'2025-09-10 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL06',
'H07',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_retract_after' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_retract_after' AS p3_marker;

SET
scenario = 'Q6_salary_before';

UPDATE
	query_params
SET
	valid_at = '2026-05-05',
	known_at = '2026-05-06 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL03')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL03',
'P003',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P025',
'PERMANENT',
'1450.00',
'2026-05-01',
'9999-12-31',
'2026-04-15 10:00:00.000000',
'2026-05-10 10:00:00.000000'),
('CONTRACT',
'CL03',
'P026',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2026-04-20 10:00:00.000000',
'2026-05-15 10:00:00.000000'),
('CONTRACT',
'CL03',
'P027',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2026-04-22 10:00:00.000000',
'2026-06-15 10:00:00.000000'),
('CONTRACT',
'CL03',
'P028',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P029',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P030',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P031',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P032',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P033',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P034',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P035',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P036',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL03',
'H04',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-09-01 10:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_salary_before' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_salary_before' AS p3_marker;

SET
scenario = 'Q6_salary_after';

UPDATE
	query_params
SET
	valid_at = '2026-05-05',
	known_at = '2026-05-11 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL03')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci,
c7 LONGTEXT COLLATE utf8mb4_unicode_ci,
c8 LONGTEXT COLLATE utf8mb4_unicode_ci,
c9 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('CONTRACT',
'CL03',
'P003',
'PERMANENT',
'1530.00',
'2025-08-29',
'9999-12-31',
'2025-09-22 14:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P025',
'PERMANENT',
'1455.00',
'2026-05-01',
'9999-12-31',
'2026-05-10 10:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P026',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2026-04-20 10:00:00.000000',
'2026-05-15 10:00:00.000000'),
('CONTRACT',
'CL03',
'P027',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2026-04-22 10:00:00.000000',
'2026-06-15 10:00:00.000000'),
('CONTRACT',
'CL03',
'P028',
'PERMANENT',
'1280.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P029',
'PERMANENT',
'1290.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P030',
'PERMANENT',
'1300.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P031',
'PERMANENT',
'1310.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P032',
'PERMANENT',
'1320.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P033',
'PERMANENT',
'1330.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P034',
'PERMANENT',
'1340.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P035',
'PERMANENT',
'1350.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('CONTRACT',
'CL03',
'P036',
'PERMANENT',
'1360.00',
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'9999-12-31 23:59:59.999999'),
('HEAD_COACH',
'CL03',
'H04',
NULL,
NULL,
'2025-07-01',
'9999-12-31',
'2025-07-01 09:00:00.000000',
'2026-09-01 10:00:00.000000');

INSERT
	INTO
	p3_actual
SELECT
	fact_kind AS c1,
	club_code AS c2,
	subject_code AS c3,
	agreement_kind AS c4,
	salary_eur AS c5,
	valid_from AS c6,
	valid_to AS c7,
	DATE_FORMAT(tx_from, '%Y-%m-%d %H:%i:%s.%f') AS c8,
	DATE_FORMAT(tx_to, '%Y-%m-%d %H:%i:%s.%f') AS c9
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6) AND (BINARY a.c7 <=> BINARY e.c7) AND (BINARY a.c8 <=> BINARY e.c8) AND (BINARY a.c9 <=> BINARY e.c9))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q6_salary_after' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q6_bitemporal_point
ORDER BY
	fact_kind,
	subject_code,
	valid_from;

SELECT
	'P3_RESULT_END:Q6_salary_after' AS p3_marker;

SET
scenario = 'Q7_season1';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('2025-07-01',
'CL01',
'2025-07-01',
'2025-08-01',
'12'),
('2025-07-01',
'CL02',
'2025-07-01',
'2025-08-01',
'12'),
('2025-07-01',
'CL03',
'2025-07-01',
'2025-08-01',
'12'),
('2025-07-01',
'CL04',
'2025-07-01',
'2025-08-01',
'12'),
('2025-07-01',
'CL05',
'2025-07-01',
'2025-08-01',
'12'),
('2025-07-01',
'CL06',
'2025-07-01',
'2025-08-01',
'0'),
('2025-08-01',
'CL01',
'2025-08-01',
'2025-09-01',
'12'),
('2025-08-01',
'CL02',
'2025-08-01',
'2025-09-01',
'13'),
('2025-08-01',
'CL03',
'2025-08-01',
'2025-09-01',
'13'),
('2025-08-01',
'CL04',
'2025-08-01',
'2025-09-01',
'13'),
('2025-08-01',
'CL05',
'2025-08-01',
'2025-09-01',
'13'),
('2025-08-01',
'CL06',
'2025-08-01',
'2025-09-01',
'1'),
('2025-09-01',
'CL01',
'2025-09-01',
'2025-10-01',
'7'),
('2025-09-01',
'CL02',
'2025-09-01',
'2025-10-01',
'13'),
('2025-09-01',
'CL03',
'2025-09-01',
'2025-10-01',
'13'),
('2025-09-01',
'CL04',
'2025-09-01',
'2025-10-01',
'13'),
('2025-09-01',
'CL05',
'2025-09-01',
'2025-10-01',
'13'),
('2025-09-01',
'CL06',
'2025-09-01',
'2025-10-01',
'1'),
('2025-10-01',
'CL01',
'2025-10-01',
'2025-11-01',
'7'),
('2025-10-01',
'CL02',
'2025-10-01',
'2025-11-01',
'13'),
('2025-10-01',
'CL03',
'2025-10-01',
'2025-11-01',
'13'),
('2025-10-01',
'CL04',
'2025-10-01',
'2025-11-01',
'13'),
('2025-10-01',
'CL05',
'2025-10-01',
'2025-11-01',
'13'),
('2025-10-01',
'CL06',
'2025-10-01',
'2025-11-01',
'1'),
('2025-11-01',
'CL01',
'2025-11-01',
'2025-12-01',
'7'),
('2025-11-01',
'CL02',
'2025-11-01',
'2025-12-01',
'13'),
('2025-11-01',
'CL03',
'2025-11-01',
'2025-12-01',
'13'),
('2025-11-01',
'CL04',
'2025-11-01',
'2025-12-01',
'13'),
('2025-11-01',
'CL05',
'2025-11-01',
'2025-12-01',
'13'),
('2025-11-01',
'CL06',
'2025-11-01',
'2025-12-01',
'1'),
('2025-12-01',
'CL01',
'2025-12-01',
'2026-01-01',
'7'),
('2025-12-01',
'CL02',
'2025-12-01',
'2026-01-01',
'12'),
('2025-12-01',
'CL03',
'2025-12-01',
'2026-01-01',
'13'),
('2025-12-01',
'CL04',
'2025-12-01',
'2026-01-01',
'13'),
('2025-12-01',
'CL05',
'2025-12-01',
'2026-01-01',
'13'),
('2025-12-01',
'CL06',
'2025-12-01',
'2026-01-01',
'1'),
('2026-01-01',
'CL01',
'2026-01-01',
'2026-02-01',
'7'),
('2026-01-01',
'CL02',
'2026-01-01',
'2026-02-01',
'9'),
('2026-01-01',
'CL03',
'2026-01-01',
'2026-02-01',
'13'),
('2026-01-01',
'CL04',
'2026-01-01',
'2026-02-01',
'13'),
('2026-01-01',
'CL05',
'2026-01-01',
'2026-02-01',
'13'),
('2026-01-01',
'CL06',
'2026-01-01',
'2026-02-01',
'1'),
('2026-02-01',
'CL01',
'2026-02-01',
'2026-03-01',
'7'),
('2026-02-01',
'CL02',
'2026-02-01',
'2026-03-01',
'9'),
('2026-02-01',
'CL03',
'2026-02-01',
'2026-03-01',
'13'),
('2026-02-01',
'CL04',
'2026-02-01',
'2026-03-01',
'13'),
('2026-02-01',
'CL05',
'2026-02-01',
'2026-03-01',
'13'),
('2026-02-01',
'CL06',
'2026-02-01',
'2026-03-01',
'1'),
('2026-03-01',
'CL01',
'2026-03-01',
'2026-04-01',
'7'),
('2026-03-01',
'CL02',
'2026-03-01',
'2026-04-01',
'11'),
('2026-03-01',
'CL03',
'2026-03-01',
'2026-04-01',
'13'),
('2026-03-01',
'CL04',
'2026-03-01',
'2026-04-01',
'13'),
('2026-03-01',
'CL05',
'2026-03-01',
'2026-04-01',
'13'),
('2026-03-01',
'CL06',
'2026-03-01',
'2026-04-01',
'1'),
('2026-04-01',
'CL01',
'2026-04-01',
'2026-05-01',
'7'),
('2026-04-01',
'CL02',
'2026-04-01',
'2026-05-01',
'11'),
('2026-04-01',
'CL03',
'2026-04-01',
'2026-05-01',
'13'),
('2026-04-01',
'CL04',
'2026-04-01',
'2026-05-01',
'13'),
('2026-04-01',
'CL05',
'2026-04-01',
'2026-05-01',
'13'),
('2026-04-01',
'CL06',
'2026-04-01',
'2026-05-01',
'1'),
('2026-05-01',
'CL01',
'2026-05-01',
'2026-06-01',
'7'),
('2026-05-01',
'CL02',
'2026-05-01',
'2026-06-01',
'11'),
('2026-05-01',
'CL03',
'2026-05-01',
'2026-06-01',
'13'),
('2026-05-01',
'CL04',
'2026-05-01',
'2026-06-01',
'13'),
('2026-05-01',
'CL05',
'2026-05-01',
'2026-06-01',
'13'),
('2026-05-01',
'CL06',
'2026-05-01',
'2026-06-01',
'1'),
('2026-06-01',
'CL01',
'2026-06-01',
'2026-07-01',
'7'),
('2026-06-01',
'CL02',
'2026-06-01',
'2026-07-01',
'12'),
('2026-06-01',
'CL03',
'2026-06-01',
'2026-07-01',
'14'),
('2026-06-01',
'CL04',
'2026-06-01',
'2026-07-01',
'14'),
('2026-06-01',
'CL05',
'2026-06-01',
'2026-07-01',
'13'),
('2026-06-01',
'CL06',
'2026-06-01',
'2026-07-01',
'1');

INSERT
	INTO
	p3_actual
SELECT
	month_start AS c1,
	club_code AS c2,
	window_start AS c3,
	window_end AS c4,
	relationship_count AS c5
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q7_season1' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

SELECT
	'P3_RESULT_END:Q7_season1' AS p3_marker;

SET
scenario = 'Q7_season2';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2026-07-01',
	period_end = '2027-07-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('2026-07-01',
'CL01',
'2026-07-01',
'2026-08-01',
'7'),
('2026-07-01',
'CL02',
'2026-07-01',
'2026-08-01',
'11'),
('2026-07-01',
'CL03',
'2026-07-01',
'2026-08-01',
'14'),
('2026-07-01',
'CL04',
'2026-07-01',
'2026-08-01',
'14'),
('2026-07-01',
'CL05',
'2026-07-01',
'2026-08-01',
'13'),
('2026-07-01',
'CL06',
'2026-07-01',
'2026-08-01',
'1'),
('2026-08-01',
'CL01',
'2026-08-01',
'2026-09-01',
'7'),
('2026-08-01',
'CL02',
'2026-08-01',
'2026-09-01',
'11'),
('2026-08-01',
'CL03',
'2026-08-01',
'2026-09-01',
'14'),
('2026-08-01',
'CL04',
'2026-08-01',
'2026-09-01',
'14'),
('2026-08-01',
'CL05',
'2026-08-01',
'2026-09-01',
'13'),
('2026-08-01',
'CL06',
'2026-08-01',
'2026-09-01',
'1'),
('2026-09-01',
'CL01',
'2026-09-01',
'2026-10-01',
'7'),
('2026-09-01',
'CL02',
'2026-09-01',
'2026-10-01',
'11'),
('2026-09-01',
'CL03',
'2026-09-01',
'2026-10-01',
'13'),
('2026-09-01',
'CL04',
'2026-09-01',
'2026-10-01',
'13'),
('2026-09-01',
'CL05',
'2026-09-01',
'2026-10-01',
'13'),
('2026-09-01',
'CL06',
'2026-09-01',
'2026-10-01',
'1'),
('2026-10-01',
'CL01',
'2026-10-01',
'2026-11-01',
'7'),
('2026-10-01',
'CL02',
'2026-10-01',
'2026-11-01',
'12'),
('2026-10-01',
'CL03',
'2026-10-01',
'2026-11-01',
'13'),
('2026-10-01',
'CL04',
'2026-10-01',
'2026-11-01',
'13'),
('2026-10-01',
'CL05',
'2026-10-01',
'2026-11-01',
'13'),
('2026-10-01',
'CL06',
'2026-10-01',
'2026-11-01',
'1'),
('2026-11-01',
'CL01',
'2026-11-01',
'2026-12-01',
'7'),
('2026-11-01',
'CL02',
'2026-11-01',
'2026-12-01',
'12'),
('2026-11-01',
'CL03',
'2026-11-01',
'2026-12-01',
'13'),
('2026-11-01',
'CL04',
'2026-11-01',
'2026-12-01',
'13'),
('2026-11-01',
'CL05',
'2026-11-01',
'2026-12-01',
'13'),
('2026-11-01',
'CL06',
'2026-11-01',
'2026-12-01',
'1'),
('2026-12-01',
'CL01',
'2026-12-01',
'2027-01-01',
'7'),
('2026-12-01',
'CL02',
'2026-12-01',
'2027-01-01',
'11'),
('2026-12-01',
'CL03',
'2026-12-01',
'2027-01-01',
'13'),
('2026-12-01',
'CL04',
'2026-12-01',
'2027-01-01',
'13'),
('2026-12-01',
'CL05',
'2026-12-01',
'2027-01-01',
'13'),
('2026-12-01',
'CL06',
'2026-12-01',
'2027-01-01',
'1'),
('2027-01-01',
'CL01',
'2027-01-01',
'2027-02-01',
'7'),
('2027-01-01',
'CL02',
'2027-01-01',
'2027-02-01',
'11'),
('2027-01-01',
'CL03',
'2027-01-01',
'2027-02-01',
'13'),
('2027-01-01',
'CL04',
'2027-01-01',
'2027-02-01',
'13'),
('2027-01-01',
'CL05',
'2027-01-01',
'2027-02-01',
'13'),
('2027-01-01',
'CL06',
'2027-01-01',
'2027-02-01',
'1'),
('2027-02-01',
'CL01',
'2027-02-01',
'2027-03-01',
'7'),
('2027-02-01',
'CL02',
'2027-02-01',
'2027-03-01',
'11'),
('2027-02-01',
'CL03',
'2027-02-01',
'2027-03-01',
'13'),
('2027-02-01',
'CL04',
'2027-02-01',
'2027-03-01',
'13'),
('2027-02-01',
'CL05',
'2027-02-01',
'2027-03-01',
'13'),
('2027-02-01',
'CL06',
'2027-02-01',
'2027-03-01',
'1'),
('2027-03-01',
'CL01',
'2027-03-01',
'2027-04-01',
'7'),
('2027-03-01',
'CL02',
'2027-03-01',
'2027-04-01',
'11'),
('2027-03-01',
'CL03',
'2027-03-01',
'2027-04-01',
'13'),
('2027-03-01',
'CL04',
'2027-03-01',
'2027-04-01',
'13'),
('2027-03-01',
'CL05',
'2027-03-01',
'2027-04-01',
'13'),
('2027-03-01',
'CL06',
'2027-03-01',
'2027-04-01',
'1'),
('2027-04-01',
'CL01',
'2027-04-01',
'2027-05-01',
'7'),
('2027-04-01',
'CL02',
'2027-04-01',
'2027-05-01',
'11'),
('2027-04-01',
'CL03',
'2027-04-01',
'2027-05-01',
'13'),
('2027-04-01',
'CL04',
'2027-04-01',
'2027-05-01',
'13'),
('2027-04-01',
'CL05',
'2027-04-01',
'2027-05-01',
'13'),
('2027-04-01',
'CL06',
'2027-04-01',
'2027-05-01',
'1'),
('2027-05-01',
'CL01',
'2027-05-01',
'2027-06-01',
'7'),
('2027-05-01',
'CL02',
'2027-05-01',
'2027-06-01',
'11'),
('2027-05-01',
'CL03',
'2027-05-01',
'2027-06-01',
'13'),
('2027-05-01',
'CL04',
'2027-05-01',
'2027-06-01',
'13'),
('2027-05-01',
'CL05',
'2027-05-01',
'2027-06-01',
'13'),
('2027-05-01',
'CL06',
'2027-05-01',
'2027-06-01',
'1'),
('2027-06-01',
'CL01',
'2027-06-01',
'2027-07-01',
'7'),
('2027-06-01',
'CL02',
'2027-06-01',
'2027-07-01',
'11'),
('2027-06-01',
'CL03',
'2027-06-01',
'2027-07-01',
'13'),
('2027-06-01',
'CL04',
'2027-06-01',
'2027-07-01',
'13'),
('2027-06-01',
'CL05',
'2027-06-01',
'2027-07-01',
'13'),
('2027-06-01',
'CL06',
'2027-06-01',
'2027-07-01',
'1');

INSERT
	INTO
	p3_actual
SELECT
	month_start AS c1,
	club_code AS c2,
	window_start AS c3,
	window_end AS c4,
	relationship_count AS c5
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q7_season2' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

SELECT
	'P3_RESULT_END:Q7_season2' AS p3_marker;

SET
scenario = 'Q7_partial';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2026-06-15',
	period_end = '2026-07-15',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('2026-06-01',
'CL01',
'2026-06-15',
'2026-07-01',
'7'),
('2026-06-01',
'CL02',
'2026-06-15',
'2026-07-01',
'12'),
('2026-06-01',
'CL03',
'2026-06-15',
'2026-07-01',
'14'),
('2026-06-01',
'CL04',
'2026-06-15',
'2026-07-01',
'14'),
('2026-06-01',
'CL05',
'2026-06-15',
'2026-07-01',
'13'),
('2026-06-01',
'CL06',
'2026-06-15',
'2026-07-01',
'1'),
('2026-07-01',
'CL01',
'2026-07-01',
'2026-07-15',
'7'),
('2026-07-01',
'CL02',
'2026-07-01',
'2026-07-15',
'11'),
('2026-07-01',
'CL03',
'2026-07-01',
'2026-07-15',
'14'),
('2026-07-01',
'CL04',
'2026-07-01',
'2026-07-15',
'14'),
('2026-07-01',
'CL05',
'2026-07-01',
'2026-07-15',
'13'),
('2026-07-01',
'CL06',
'2026-07-01',
'2026-07-15',
'1');

INSERT
	INTO
	p3_actual
SELECT
	month_start AS c1,
	club_code AS c2,
	window_start AS c3,
	window_end AS c4,
	relationship_count AS c5
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q7_partial' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

SELECT
	'P3_RESULT_END:Q7_partial' AS p3_marker;

SET
scenario = 'Q7_one_day';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-08-30',
	period_end = '2025-08-31',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('2025-08-01',
'CL01',
'2025-08-30',
'2025-08-31',
'8'),
('2025-08-01',
'CL02',
'2025-08-30',
'2025-08-31',
'13'),
('2025-08-01',
'CL03',
'2025-08-30',
'2025-08-31',
'13'),
('2025-08-01',
'CL04',
'2025-08-30',
'2025-08-31',
'13'),
('2025-08-01',
'CL05',
'2025-08-30',
'2025-08-31',
'13'),
('2025-08-01',
'CL06',
'2025-08-30',
'2025-08-31',
'0');

INSERT
	INTO
	p3_actual
SELECT
	month_start AS c1,
	club_code AS c2,
	window_start AS c3,
	window_end AS c4,
	relationship_count AS c5
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q7_one_day' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q7_monthly_relationships
ORDER BY
	month_start,
	club_code;

SELECT
	'P3_RESULT_END:Q7_one_day' AS p3_marker;

SET
scenario = 'Q8_all_gaps';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		player_id
	FROM
		player
	WHERE
		player_code = 'P060')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('P006',
'CL02',
'2026-07-01',
'2026-10-01',
'92'),
('P013',
'CL02',
'2025-12-01',
'2026-02-01',
'62'),
('P014',
'CL02',
'2025-12-15',
'2026-03-01',
'76'),
('P015',
'CL02',
'2025-12-20',
'2026-03-10',
'80');

INSERT
	INTO
	p3_actual
SELECT
	player_code AS c1,
	club_code AS c2,
	gap_from AS c3,
	gap_to AS c4,
	gap_days AS c5
FROM
	v_q8_relationship_gaps
ORDER BY
	player_code,
	club_code,
	gap_from;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q8_all_gaps' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_q8_relationship_gaps
ORDER BY
	player_code,
	club_code,
	gap_from;

SELECT
	'P3_RESULT_END:Q8_all_gaps' AS p3_marker;

SET
scenario = 'Q3_all_old_new';

UPDATE
	query_params
SET
	valid_at = '2026-03-02',
	known_at = '2026-09-21 12:00:00.000000',
	period_start = '2025-07-01',
	period_end = '2026-07-01',
	subject_id =(
	SELECT
		club_id
	FROM
		club
	WHERE
		club_code = 'CL01')
WHERE
	params_id = 1;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

CREATE TEMPORARY TABLE p3_expected (c1 LONGTEXT COLLATE utf8mb4_unicode_ci,
c2 LONGTEXT COLLATE utf8mb4_unicode_ci,
c3 LONGTEXT COLLATE utf8mb4_unicode_ci,
c4 LONGTEXT COLLATE utf8mb4_unicode_ci,
c5 LONGTEXT COLLATE utf8mb4_unicode_ci,
c6 LONGTEXT COLLATE utf8mb4_unicode_ci);

CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;

INSERT
	INTO
	p3_expected
VALUES ('T02',
'CONTRACT',
'P001',
'[{"business_key":"P001/CL01","value":"1010.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P001/CL01","value":"1010.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2025-08-31"},{"business_key":"P001/CL06","value":"1510.00","agreement_kind":"PERMANENT","valid_from":"2025-08-31","valid_to":"9999-12-31"}]',
'0'),
('T03',
'CONTRACT',
'P002',
'[{"business_key":"P002/CL01","value":"1020.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P002/CL01","value":"1020.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2025-08-30"},{"business_key":"P002/CL02","value":"1520.00","agreement_kind":"PERMANENT","valid_from":"2025-08-30","valid_to":"9999-12-31"}]',
'0'),
('T04',
'CONTRACT',
'P003',
'[{"business_key":"P003/CL01","value":"1030.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P003/CL01","value":"1030.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2025-08-29"},{"business_key":"P003/CL03","value":"1530.00","agreement_kind":"PERMANENT","valid_from":"2025-08-29","valid_to":"9999-12-31"}]',
'0'),
('T05',
'CLUB',
'CL01',
'[{"business_key":"CL01","value":"1000000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL01","value":"1000000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2025-11-01"},{"business_key":"CL01","value":"1100000.00","agreement_kind":null,"valid_from":"2025-11-01","valid_to":"9999-12-31"}]',
'0'),
('T06',
'CONTRACT',
'P004',
'[{"business_key":"P004/CL01","value":"1040.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P004/CL01","value":"1040.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2025-08-28"},{"business_key":"P004/CL04","value":"1540.00","agreement_kind":"PERMANENT","valid_from":"2025-08-28","valid_to":"9999-12-31"}]',
'0'),
('T07',
'CONTRACT',
'P005',
'[{"business_key":"P005/CL01","value":"1050.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P005/CL01","value":"1050.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2025-08-27"},{"business_key":"P005/CL05","value":"1550.00","agreement_kind":"PERMANENT","valid_from":"2025-08-27","valid_to":"9999-12-31"}]',
'0'),
('T08',
'CLUB',
'CL02',
'[{"business_key":"CL02","value":"1100000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL02","value":"1100000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2025-12-01"},{"business_key":"CL02","value":"1200000.00","agreement_kind":null,"valid_from":"2025-12-01","valid_to":"9999-12-31"}]',
'0'),
('T09',
'CLUB',
'CL03',
'[{"business_key":"CL03","value":"1200000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL03","value":"1200000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-01-01"},{"business_key":"CL03","value":"1300000.00","agreement_kind":null,"valid_from":"2026-01-01","valid_to":"9999-12-31"}]',
'0'),
('T13',
'CONTRACT',
'P016',
'[{"business_key":"P016/CL02","value":"1160.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P016/CL02","value":"1160.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2026-01-01"}]',
'0'),
('T15',
'CONTRACT',
'P013',
NULL,
'[{"business_key":"P013/CL02","value":"1130.00","agreement_kind":"PERMANENT","valid_from":"2026-02-01","valid_to":"9999-12-31"}]',
'0'),
('T16',
'HEAD_COACH',
'CL02',
'[{"business_key":"CL02","value":"H03","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL02","value":"H03","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-01-10"},{"business_key":"CL02","value":"H08","agreement_kind":null,"valid_from":"2026-01-10","valid_to":"9999-12-31"}]',
'0'),
('T17',
'CONTRACT',
'P014',
NULL,
'[{"business_key":"P014/CL02","value":"1140.00","agreement_kind":"PERMANENT","valid_from":"2026-03-01","valid_to":"9999-12-31"}]',
'0'),
('T18',
'HEAD_COACH',
'CL01',
'[{"business_key":"CL01","value":"H01","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL01","value":"H01","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-03-01"},{"business_key":"CL01","value":"H02","agreement_kind":null,"valid_from":"2026-03-01","valid_to":"9999-12-31"}]',
'0'),
('T19',
'HEAD_COACH',
'CL01',
'[{"business_key":"CL01","value":"H01","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-03-01"},{"business_key":"CL01","value":"H02","agreement_kind":null,"valid_from":"2026-03-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL01","value":"H01","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-03-03"},{"business_key":"CL01","value":"H02","agreement_kind":null,"valid_from":"2026-03-03","valid_to":"9999-12-31"}]',
'0'),
('T20',
'CONTRACT',
'P015',
NULL,
'[{"business_key":"P015/CL02","value":"1150.00","agreement_kind":"PERMANENT","valid_from":"2026-03-10","valid_to":"9999-12-31"}]',
'0'),
('T21',
'CONTRACT',
'P060',
NULL,
'[{"business_key":"P060/CL06","value":"600.00","agreement_kind":"LOAN","valid_from":"2026-04-01","valid_to":"2026-05-01"}]',
'0'),
('T22',
'CONTRACT',
'P025',
'[{"business_key":"P025/CL03","value":"1250.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P025/CL03","value":"1250.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2026-05-01"},{"business_key":"P025/CL03","value":"1450.00","agreement_kind":"PERMANENT","valid_from":"2026-05-01","valid_to":"9999-12-31"}]',
'0'),
('T23',
'CONTRACT',
'P026',
'[{"business_key":"P026/CL03","value":"1260.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P026/CL03","value":"1280.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'0'),
('T24',
'CONTRACT',
'P027',
'[{"business_key":"P027/CL03","value":"1270.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P027/CL03","value":"1290.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'0'),
('T26',
'CONTRACT',
'P025',
'[{"business_key":"P025/CL03","value":"1450.00","agreement_kind":"PERMANENT","valid_from":"2026-05-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P025/CL03","value":"1455.00","agreement_kind":"PERMANENT","valid_from":"2026-05-01","valid_to":"9999-12-31"}]',
'0'),
('T27',
'CONTRACT',
'P026',
'[{"business_key":"P026/CL03","value":"1280.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P026/CL03","value":"1280.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2026-06-01"},{"business_key":"P026/CL03","value":"1480.00","agreement_kind":"PERMANENT","valid_from":"2026-06-01","valid_to":"9999-12-31"}]',
'0'),
('T28',
'CONTRACT',
'P006',
NULL,
'[{"business_key":"P006/CL02","value":"600.00","agreement_kind":"LOAN","valid_from":"2026-06-01","valid_to":"2026-09-01"}]',
'0'),
('T29',
'CONTRACT',
'P007',
NULL,
'[{"business_key":"P007/CL03","value":"700.00","agreement_kind":"LOAN","valid_from":"2026-06-01","valid_to":"2026-09-01"}]',
'0'),
('T30',
'CONTRACT',
'P008',
NULL,
'[{"business_key":"P008/CL04","value":"800.00","agreement_kind":"LOAN","valid_from":"2026-06-01","valid_to":"2026-09-01"}]',
'0'),
('T31',
'CONTRACT',
'P027',
'[{"business_key":"P027/CL03","value":"1290.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P027/CL03","value":"1290.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2026-07-01"},{"business_key":"P027/CL03","value":"1490.00","agreement_kind":"PERMANENT","valid_from":"2026-07-01","valid_to":"9999-12-31"}]',
'0'),
('T33',
'CONTRACT',
'P027',
'[{"business_key":"P027/CL03","value":"1490.00","agreement_kind":"PERMANENT","valid_from":"2026-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P027/CL03","value":"1495.00","agreement_kind":"PERMANENT","valid_from":"2026-07-01","valid_to":"9999-12-31"}]',
'0'),
('T34',
'CLUB',
'CL04',
'[{"business_key":"CL04","value":"1300000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL04","value":"1300000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-08-01"},{"business_key":"CL04","value":"1430000.00","agreement_kind":null,"valid_from":"2026-08-01","valid_to":"9999-12-31"}]',
'0'),
('T34',
'CONTRACT',
'P037',
'[{"business_key":"P037/CL04","value":"1370.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P037/CL04","value":"1370.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2026-08-01"},{"business_key":"P037/CL04","value":"1570.00","agreement_kind":"PERMANENT","valid_from":"2026-08-01","valid_to":"9999-12-31"}]',
'0'),
('T35',
'CLUB',
'CL05',
'[{"business_key":"CL05","value":"1400000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL05","value":"1400000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-09-01"},{"business_key":"CL05","value":"1540000.00","agreement_kind":null,"valid_from":"2026-09-01","valid_to":"9999-12-31"}]',
'0'),
('T35',
'CONTRACT',
'P049',
'[{"business_key":"P049/CL05","value":"1490.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"P049/CL05","value":"1490.00","agreement_kind":"PERMANENT","valid_from":"2025-07-01","valid_to":"2026-09-01"},{"business_key":"P049/CL05","value":"1740.00","agreement_kind":"PERMANENT","valid_from":"2026-09-01","valid_to":"9999-12-31"}]',
'0'),
('T36',
'HEAD_COACH',
'CL03',
'[{"business_key":"CL03","value":"H04","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL03","value":"H04","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-10-01"},{"business_key":"CL03","value":"H01","agreement_kind":null,"valid_from":"2026-10-01","valid_to":"9999-12-31"}]',
'0'),
('T37',
'CLUB',
'CL06',
'[{"business_key":"CL06","value":"1500000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"9999-12-31"}]',
'[{"business_key":"CL06","value":"1500000.00","agreement_kind":null,"valid_from":"2025-07-01","valid_to":"2026-11-01"},{"business_key":"CL06","value":"1650000.00","agreement_kind":null,"valid_from":"2026-11-01","valid_to":"9999-12-31"}]',
'0'),
('T38',
'CONTRACT',
'P006',
NULL,
'[{"business_key":"P006/CL02","value":"650.00","agreement_kind":"LOAN","valid_from":"2026-10-01","valid_to":"2026-12-01"}]',
'0');

INSERT
	INTO
	p3_actual
SELECT
	event_ref AS c1,
	fact_family AS c2,
	subject_code AS c3,
	JSON_COMPACT(old_values) AS c4,
	JSON_COMPACT(new_values) AS c5,
	ambiguous_closure AS c6
FROM
	v_q3_event_audit
ORDER BY
	event_ref,
	fact_family,
	subject_code;

IF (
SELECT
	COUNT(*)
FROM
	p3_actual)<>(
SELECT
	COUNT(*)
FROM
	p3_expected)
OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE (BINARY a.c1 <=> BINARY e.c1) AND (BINARY a.c2 <=> BINARY e.c2) AND (BINARY a.c3 <=> BINARY e.c3) AND (BINARY a.c4 <=> BINARY e.c4) AND (BINARY a.c5 <=> BINARY e.c5) AND (BINARY a.c6 <=> BINARY e.c6))<> 1) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = scenario;
END IF;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'P3_Q0: positive scenario contaminated';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q3_all_old_new' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	event_ref AS c1,
	fact_family AS c2,
	subject_code AS c3,
	JSON_COMPACT(old_values) AS c4,
	JSON_COMPACT(new_values) AS c5,
	ambiguous_closure AS c6
FROM
	v_q3_event_audit
ORDER BY
	event_ref,
	fact_family,
	subject_code;

SELECT
	'P3_RESULT_END:Q3_all_old_new' AS p3_marker;

IF COALESCE(@p3_negative, 0)= 1 THEN
  SET
scenario = 'Q0_negative_I1';

START TRANSACTION;

SET
@sim_now = NULL;

INSERT
	INTO
	tx_registry(tx_time, author, reason)
VALUES(fn_effective_time(), 'Part C test', 'Q0 I1 fixture rollback');

SET
xtx = LAST_INSERT_ID();

INSERT
	INTO
	contract_version(contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_id)
  SELECT
	v.contract_id,
	v.agreement_kind,
	v.salary_eur,
	v.valid_from,
	v.valid_to,
	r.tx_time,
	xtx
FROM
	contract_version v
JOIN contract a
		USING(contract_id)
JOIN player p
		USING(player_id)
JOIN tx_registry r ON
	r.tx_id = xtx
WHERE
	p.player_code = 'P018'
	AND v.tx_to = '9999-12-31 23:59:59.999999';

SET
xv = LAST_INSERT_ID();

IF (
SELECT
	COUNT(*)
FROM
	v_integrity_violations
WHERE
	invariant_code = 'I1'
	AND source_table = 'contract_version'
	AND (version_id = xv
		OR conflicting_version_id = xv))<> 1
OR (
SELECT
	COUNT(*)
FROM
	v_integrity_violations)<> 1 THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'Q0 I1 exact diagnosis missing';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q0_negative_I1' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_integrity_violations;

SELECT
	'P3_RESULT_END:Q0_negative_I1' AS p3_marker;

ROLLBACK;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'Q0 after I1 rollback';
END IF;

SET
scenario = 'Q0_negative_I3';

START TRANSACTION;

INSERT
	INTO
	tx_registry(tx_time, author, reason)
VALUES(fn_effective_time(), 'Part C test', 'Q0 I3 fixture rollback');

SET
xtx = LAST_INSERT_ID();

INSERT
	INTO
	head_coach_role_version(role_id, coach_id, valid_from, valid_to, tx_from, tx_id)
  SELECT
	a.role_id,
	h.coach_id,
	'2026-04-01',
	'2026-04-02',
	r.tx_time,
	xtx
FROM
	head_coach_role a
JOIN club c
		USING(club_id)
CROSS JOIN coach h
JOIN tx_registry r ON
	r.tx_id = xtx
WHERE
	c.club_code = 'CL01'
	AND h.coach_code = 'H08';

SET
xv = LAST_INSERT_ID();

IF (
SELECT
	COUNT(*)
FROM
	v_integrity_violations
WHERE
	invariant_code = 'I3'
	AND (version_id = xv
		OR conflicting_version_id = xv))<> 1
OR (
SELECT
	COUNT(*)
FROM
	v_integrity_violations
WHERE
	invariant_code = 'I1'
	AND source_table = 'head_coach_role_version')<> 1
OR (
SELECT
	COUNT(*)
FROM
	v_integrity_violations)<> 2 THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'Q0 I3 exact diagnosis missing';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q0_negative_I3' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_integrity_violations
ORDER BY
	invariant_code;

SELECT
	'P3_RESULT_END:Q0_negative_I3' AS p3_marker;

ROLLBACK;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'Q0 after I3 rollback';
END IF;

SET
scenario = 'Q0_I2_union_then_gap';

START TRANSACTION;

INSERT
	INTO
	club(club_code)
VALUES('P3_FIXTURE_UNION');

SET
xclub = LAST_INSERT_ID();

INSERT
	INTO
	contract(player_id, club_id)
SELECT
	player_id,
	xclub
FROM
	player
WHERE
	player_code = 'P060';

SET
xcontract = LAST_INSERT_ID();

INSERT
	INTO
	tx_registry(tx_time, author, reason)
VALUES(fn_effective_time(), 'Part C test', 'Q0 I2 union fixture rollback');

SET
xtx = LAST_INSERT_ID();

INSERT
	INTO
	club_version(club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_id)
  SELECT
	xclub,
	'Fixture',
	1,
	'2026-01-01',
	'2026-02-01',
	tx_time,
	xtx
FROM
	tx_registry
WHERE
	tx_id = xtx;

INSERT
	INTO
	club_version(club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_id)
  SELECT
	xclub,
	'Fixture',
	1,
	'2026-02-01',
	'2026-03-01',
	tx_time,
	xtx
FROM
	tx_registry
WHERE
	tx_id = xtx;

SET
xv2 = LAST_INSERT_ID();

INSERT
	INTO
	contract_version(contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_id)
  SELECT
	xcontract,
	'LOAN',
	1,
	'2026-01-15',
	'2026-02-15',
	tx_time,
	xtx
FROM
	tx_registry
WHERE
	tx_id = xtx;

SET
xv = LAST_INSERT_ID();

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'Q0 I2 adjacent union rejected';
END IF;

SET
checks = checks + 1;

INSERT
	INTO
	tx_registry(tx_time, author, reason)
VALUES(fn_effective_time(), 'Part C test', 'Q0 I2 gap fixture rollback');

SET
@write_tx_id = LAST_INSERT_ID();

UPDATE
	club_version
SET
	tx_to =(
	SELECT
		tx_time
	FROM
		tx_registry
	WHERE
		tx_id = @write_tx_id)
WHERE
	version_id = xv2;

INSERT
	INTO
	club_version(club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_id)
  SELECT
	xclub,
	'Fixture',
	1,
	'2026-02-02',
	'2026-03-01',
	tx_time,
	tx_id
FROM
	tx_registry
WHERE
	tx_id = @write_tx_id;

IF (
SELECT
	COUNT(*)
FROM
	v_integrity_violations
WHERE
	invariant_code = 'I2'
	AND source_table = 'contract_version'
	AND business_key = xcontract
	AND version_id = xv)<> 1
OR (
SELECT
	COUNT(*)
FROM
	v_integrity_violations)<> 1 THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'Q0 I2 gap diagnosis missing';
END IF;

SELECT
	'P3_RESULT_BEGIN:Q0_negative_I2' AS p3_marker;

SELECT
	*
FROM
	query_params;

SELECT
	*
FROM
	v_integrity_violations;

SELECT
	'P3_RESULT_END:Q0_negative_I2' AS p3_marker;

ROLLBACK;

SET
@write_tx_id = NULL;

SET
checks = checks + 1;

IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET
MESSAGE_TEXT = 'Q0 after I2 rollback';
END IF;

SELECT
	'negative executed in isolated clone' AS negative_mode;
ELSE
SELECT
	'negative not activated; positive inspection only' AS negative_mode;
END IF;

UPDATE
	query_params
SET
	valid_at = sv,
	known_at = sk,
	period_start = ss,
	period_end = se,
	subject_id = sid
WHERE
	params_id = 1;

SET
@sim_now = NULL,
@write_tx_id = NULL;

DROP TEMPORARY TABLE IF EXISTS p3_expected;

DROP TEMPORARY TABLE IF EXISTS p3_actual;

SELECT
	'PASS' AS verdict,
	checks AS assertions,
	UTC_DATE() AS evaluated_utc_date;

END$$
DELIMITER ;
