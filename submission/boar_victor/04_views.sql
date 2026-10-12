-- Part C. Only views are replaced, in dependency order; selected database only.
-- Half-open VT/TT, UTC. Public parameter contracts are in docs/query_catalog.md.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET time_zone='+00:00';
CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_integrity_violations AS
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

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_p3_contract_facts AS
SELECT v.*,a.player_id,a.club_id,p.player_code,p.full_name player_name,c.club_code
FROM contract_version v JOIN contract a USING(contract_id) JOIN player p USING(player_id) JOIN club c USING(club_id);

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q1_current_contracts AS
SELECT f.*,cv.club_name,UTC_DATE() evaluation_date
FROM v_p3_contract_facts f CROSS JOIN query_params p
JOIN club_version cv ON cv.club_id=f.club_id AND cv.tx_to='9999-12-31 23:59:59.999999'
AND cv.valid_from<=UTC_DATE() AND UTC_DATE()<cv.valid_to
WHERE p.params_id=1 AND f.player_id=p.subject_id
AND f.tx_to='9999-12-31 23:59:59.999999' AND f.valid_from<=UTC_DATE() AND UTC_DATE()<f.valid_to;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q2_coach_tenures AS
WITH scan AS (
 SELECT v.*,a.club_id,LAG(coach_id) OVER(PARTITION BY role_id ORDER BY valid_from,version_id) prior_coach,
 LAG(valid_to) OVER(PARTITION BY role_id ORDER BY valid_from,version_id) prior_end
 FROM head_coach_role_version v JOIN head_coach_role a USING(role_id)
 CROSS JOIN query_params p WHERE v.tx_to='9999-12-31 23:59:59.999999' AND a.club_id=p.subject_id AND p.params_id=1
), marks AS (
 SELECT *,IF(prior_coach=coach_id AND prior_end=valid_from,0,1) new_tenure FROM scan
), islands AS (
 SELECT *,SUM(new_tenure) OVER(PARTITION BY role_id ORDER BY valid_from,version_id ROWS UNBOUNDED PRECEDING) island FROM marks
), tenures AS (
 SELECT role_id,club_id,coach_id,island,MIN(valid_from) tenure_from,MAX(valid_to) tenure_to
 FROM islands GROUP BY role_id,club_id,coach_id,island
)
SELECT t.role_id,c.club_code,h.coach_code,h.full_name coach_name,t.tenure_from,t.tenure_to,
 CASE WHEN tenure_to='9999-12-31' THEN NULL ELSE DATEDIFF(tenure_to,tenure_from) END tenure_days,
 GREATEST(DATEDIFF(LEAST(UTC_DATE(),tenure_to),tenure_from),0) elapsed_days,
 CASE WHEN UTC_DATE()<tenure_from THEN 'SCHEDULED' WHEN UTC_DATE()>=tenure_to THEN 'ENDED' ELSE 'ACTIVE' END tenure_status,
 UTC_DATE() evaluation_date
FROM tenures t JOIN club c USING(club_id) JOIN coach h USING(coach_id);

-- Q3 facts are normalized from actual history, not narrative values.
CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_p3_audit_facts AS
SELECT 'CONTRACT' fact_family,p.player_code subject_code,CONCAT(p.player_code,'/',c.club_code) business_key,
 c.club_code,CAST(v.salary_eur AS CHAR(120)) fact_value,v.agreement_kind,
 v.version_id,v.valid_from,v.valid_to,v.tx_from,v.tx_to,v.tx_id
FROM contract_version v JOIN contract a USING(contract_id) JOIN player p USING(player_id) JOIN club c USING(club_id)
UNION ALL
SELECT 'CLUB',c.club_code,c.club_code,c.club_code,CAST(v.budget_eur AS CHAR(120)),NULL,
 v.version_id,v.valid_from,v.valid_to,v.tx_from,v.tx_to,v.tx_id FROM club_version v JOIN club c USING(club_id)
UNION ALL
SELECT 'HEAD_COACH',c.club_code,c.club_code,c.club_code,h.coach_code,NULL,
 v.version_id,v.valid_from,v.valid_to,v.tx_from,v.tx_to,v.tx_id
FROM head_coach_role_version v JOIN head_coach_role a USING(role_id) JOIN club c USING(club_id) JOIN coach h USING(coach_id);

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_p3_audit_events AS
SELECT r.tx_id,LEFT(r.reason,3) event_ref,r.tx_time,r.reason,
 GROUP_CONCAT(e.event_code ORDER BY e.event_code SEPARATOR ',') event_codes,
 MAX(e.event_code='E2') is_proactive,MAX(e.event_code='E3') is_late,MAX(e.event_code='E4') is_correction,
 (SELECT COUNT(*) FROM tx_registry z WHERE z.tx_time=r.tx_time) same_time_events
FROM tx_registry r JOIN tx_event_tag e USING(tx_id)
GROUP BY r.tx_id,r.reason,r.tx_time
HAVING MAX(e.event_code IN ('E2','E3','E4'))=1;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_p3_audit_components AS
SELECT DISTINCT e.tx_id,f.fact_family,f.subject_code
FROM v_p3_audit_events e JOIN v_p3_audit_facts f ON f.tx_id=e.tx_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_p3_audit_old AS
SELECT c.tx_id closing_tx_id,f.*
FROM v_p3_audit_components c JOIN v_p3_audit_events e ON e.tx_id=c.tx_id
JOIN v_p3_audit_facts f ON f.fact_family=c.fact_family AND f.subject_code=c.subject_code
AND f.tx_to=e.tx_time WHERE e.same_time_events=1;

CREATE OR REPLACE ALGORITHM=TEMPTABLE SQL SECURITY INVOKER VIEW v_p3_audit_candidates AS
SELECT n.tx_id,n.fact_family,n.subject_code,n.valid_from,n.valid_to,e.is_correction,
 NOT EXISTS (SELECT 1 FROM v_p3_audit_old o WHERE o.closing_tx_id=n.tx_id
 AND o.fact_family=n.fact_family AND o.subject_code=n.subject_code AND o.business_key=n.business_key
 AND o.fact_value=n.fact_value AND (o.agreement_kind <=> n.agreement_kind)
 AND o.valid_from<=n.valid_from AND n.valid_from<o.valid_to) AS changed_at_start,
 EXISTS (SELECT 1 FROM v_p3_audit_old o WHERE o.closing_tx_id=n.tx_id
 AND o.fact_family=n.fact_family AND o.subject_code=n.subject_code AND o.business_key=n.business_key
 AND n.valid_to<o.valid_to) AS shortened_end
FROM v_p3_audit_facts n JOIN v_p3_audit_events e ON e.tx_id=n.tx_id;
CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_p3_audit_dates AS
SELECT tx_id,fact_family,subject_code,
 CASE WHEN fact_family='HEAD_COACH' AND MAX(is_correction)=1 THEN MAX(valid_from)
 ELSE COALESCE(MIN(CASE WHEN changed_at_start THEN valid_from END),MIN(CASE WHEN shortened_end THEN valid_to END)) END effective_date
FROM v_p3_audit_candidates GROUP BY tx_id,fact_family,subject_code;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q3_event_audit AS
SELECT e.tx_id,e.event_ref,e.tx_time,d.fact_family,d.subject_code,e.event_codes,
 e.is_proactive,e.is_late,e.is_correction,d.effective_date,
 DATEDIFF(DATE(e.tx_time),d.effective_date) delay_days,
 GREATEST(-DATEDIFF(DATE(e.tx_time),d.effective_date),0) lead_days,
 (SELECT JSON_ARRAYAGG(JSON_OBJECT('business_key',o.business_key,'value',o.fact_value,'agreement_kind',o.agreement_kind,
 'valid_from',o.valid_from,'valid_to',o.valid_to) ORDER BY o.business_key,o.valid_from,o.version_id)
 FROM v_p3_audit_old o WHERE o.closing_tx_id=e.tx_id AND o.fact_family=d.fact_family AND o.subject_code=d.subject_code) old_values,
 (SELECT JSON_ARRAYAGG(JSON_OBJECT('business_key',n.business_key,'value',n.fact_value,'agreement_kind',n.agreement_kind,
 'valid_from',n.valid_from,'valid_to',n.valid_to) ORDER BY n.business_key,n.valid_from,n.version_id)
 FROM v_p3_audit_facts n WHERE n.tx_id=e.tx_id AND n.fact_family=d.fact_family AND n.subject_code=d.subject_code) new_values,
 e.same_time_events,(e.same_time_events<>1) ambiguous_closure,e.reason
FROM v_p3_audit_events e JOIN v_p3_audit_dates d ON d.tx_id=e.tx_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q4_period_relationships AS
SELECT f.*,p.period_start,p.period_end,
 (f.valid_from<p.period_end AND p.period_start<f.valid_to) at_some_point,
 (f.valid_from<=p.period_start AND p.period_end<=f.valid_to) throughout
FROM v_p3_contract_facts f CROSS JOIN query_params p
WHERE p.params_id=1 AND f.tx_to='9999-12-31 23:59:59.999999';
CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q5_contracts_as_known AS
SELECT f.*,p.known_at FROM v_p3_contract_facts f CROSS JOIN query_params p
WHERE p.params_id=1 AND f.tx_from<=p.known_at AND p.known_at<f.tx_to;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q6_bitemporal_point AS
SELECT 'HEAD_COACH' fact_kind,c.club_code,h.coach_code subject_code,h.full_name subject_name,
 CAST(NULL AS CHAR(9)) agreement_kind,CAST(NULL AS DECIMAL(12,2)) salary_eur,
 v.version_id,v.valid_from,v.valid_to,v.tx_from,v.tx_to,v.tx_id
FROM head_coach_role_version v JOIN head_coach_role a USING(role_id) JOIN club c USING(club_id)
JOIN coach h USING(coach_id) CROSS JOIN query_params p
WHERE p.params_id=1 AND a.club_id=p.subject_id AND v.valid_from<=p.valid_at AND p.valid_at<v.valid_to
AND v.tx_from<=p.known_at AND p.known_at<v.tx_to
UNION ALL
SELECT 'CONTRACT',f.club_code,f.player_code,f.player_name,f.agreement_kind,f.salary_eur,
 f.version_id,f.valid_from,f.valid_to,f.tx_from,f.tx_to,f.tx_id
FROM v_p3_contract_facts f CROSS JOIN query_params p
WHERE p.params_id=1 AND f.club_id=p.subject_id AND f.valid_from<=p.valid_at AND p.valid_at<f.valid_to
AND f.tx_from<=p.known_at AND p.known_at<f.tx_to;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q7_monthly_relationships AS
WITH RECURSIVE months AS (
 SELECT CAST(DATE_FORMAT(period_start,'%Y-%m-01') AS DATE) month_start,period_start,period_end
 FROM query_params WHERE params_id=1
 UNION ALL
 SELECT CAST(DATE_ADD(month_start,INTERVAL 1 MONTH) AS DATE),period_start,period_end
 FROM months WHERE DATE_ADD(month_start,INTERVAL 1 MONTH)<period_end
), windows AS (
 SELECT month_start,GREATEST(month_start,period_start) window_start,
 LEAST(DATE_ADD(month_start,INTERVAL 1 MONTH),period_end) window_end FROM months
)
SELECT w.month_start,c.club_code,w.window_start,w.window_end,COUNT(DISTINCT v.contract_id) relationship_count
FROM windows w CROSS JOIN club c LEFT JOIN contract a ON a.club_id=c.club_id
LEFT JOIN contract_version v ON v.contract_id=a.contract_id AND v.tx_to='9999-12-31 23:59:59.999999'
AND v.valid_from<w.window_end AND w.window_start<v.valid_to
GROUP BY w.month_start,c.club_code,w.window_start,w.window_end;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_q8_relationship_gaps AS
WITH scan AS (
 SELECT contract_id,version_id,valid_from,valid_to,
 MAX(valid_to) OVER(PARTITION BY contract_id ORDER BY valid_from,version_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) prior_end
 FROM contract_version WHERE tx_to='9999-12-31 23:59:59.999999'
), marks AS (
 SELECT *,IF(prior_end IS NULL OR prior_end<valid_from,1,0) new_island FROM scan
), numbered AS (
 SELECT *,SUM(new_island) OVER(PARTITION BY contract_id ORDER BY valid_from,version_id ROWS UNBOUNDED PRECEDING) island FROM marks
), united AS (
 SELECT contract_id,island,MIN(valid_from) valid_from,MAX(valid_to) valid_to FROM numbered GROUP BY contract_id,island
), neighbors AS (
 SELECT *,LAG(valid_to) OVER(PARTITION BY contract_id ORDER BY valid_from) gap_from FROM united
)
SELECT a.contract_id,p.player_code,c.club_code,n.gap_from,n.valid_from gap_to,DATEDIFF(n.valid_from,n.gap_from) gap_days
FROM neighbors n JOIN contract a USING(contract_id) JOIN player p USING(player_id) JOIN club c USING(club_id)
WHERE n.gap_from<n.valid_from;
