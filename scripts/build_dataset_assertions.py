#!/usr/bin/env python3
"""Emit independent plan expectations and a read-only business audit. Never connects to DB.
Expected values are derived only from the user's phase-2 specification, not replay SQL.
"""
import json
from collections import Counter
from datetime import date, timedelta
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
INF = '9999-12-31 23:59:59.999999'
KNOWN = '2026-09-21 12:00:00.000000'
cases = []
def add(id, sql, expected, reason, params=None):
    cases.append(dict(id=id, sql=sql.strip().rstrip(';'), expected=[[str(v) for v in row] for row in expected], reason=reason, params=params or {}))
def count(id, table, n, where='1=1', reason='Volum literal din plan, secțiunea 8.'):
    add(id, f'SELECT COUNT(*) AS c1 FROM {table} WHERE {where}', [[n]], reason)
def snap(v, k):
    return f"v.valid_from <= '{v}' AND '{v}' < v.valid_to AND v.tx_from <= '{k}' AND '{k}' < v.tx_to"
# All emitted columns have stable cN aliases, independent of surrogate identifiers.
for table,n in [('player',60),('coach',8),('club',6),('season',2),('contract',69),('head_coach_role',6),('tx_registry',38),('tx_event_tag',53),('club_version',18),('contract_version',98),('head_coach_role_version',15),('query_params',1)]:
    count('count_'+table,table,n)
for t,n in [('club_version',12),('contract_version',77),('head_coach_role_version',10)]:
    count('current_'+t,t,n,f"tx_to = '{INF}'")
add('total_versions', 'SELECT (SELECT COUNT(*) FROM club_version)+(SELECT COUNT(*) FROM contract_version)+(SELECT COUNT(*) FROM head_coach_role_version) AS c1', [[131]], '6+60+7 versions in E1, 58 later assertions: 131.')
add('current_contract_anchors',f"SELECT COUNT(DISTINCT contract_id) AS c1 FROM contract_version WHERE tx_to='{INF}'",[[68]],'69 anchors minus retracted P060–CL06.')
add('players','SELECT player_code AS c1, full_name AS c2, birth_date AS c3 FROM player ORDER BY player_code',[[f'P{i:03}',f'Jucător Fictiv {i:03}',(date(1995,1,1)+timedelta(days=37*(i-1))).isoformat()] for i in range(1,61)],'Deterministic people specified in section 4; materialized literals, no database input.')
names=['Andrei Ionescu','Mihai Popescu','Radu Marin','Vlad Stan','Sorin Dima','Dan Rusu','Paul Muntean','Alex Matei']
add('coaches','SELECT coach_code AS c1,full_name AS c2,birth_date AS c3 FROM coach ORDER BY coach_code',[[f'H{i:02}',n,f'{1969+i}-01-01'] for i,n in enumerate(names,1)],'Eight fixed fictional identities.')
add('seasons','SELECT season_name AS c1,period_start AS c2,period_end AS c3 FROM season ORDER BY period_start', [['2025/2026','2025-07-01','2026-07-01'],['2026/2027','2026-07-01','2027-07-01']],'Two exact reference seasons.')
add('params_final',"SELECT q.params_id AS c1,q.valid_at AS c2,DATE_FORMAT(q.known_at,'%Y-%m-%d %H:%i:%s.%f') AS c3,q.period_start AS c4,q.period_end AS c5,c.club_code AS c6 FROM query_params q LEFT JOIN club c ON c.club_id=q.subject_id ORDER BY q.params_id",[['1','2026-03-02','2026-03-16 12:00:00.000000','2025-07-01','2026-07-01','CL01']],'subject_id resolves to the real CL01 identifier; never assumes ID=1.')
add('event_counts','SELECT event_code AS c1,COUNT(DISTINCT tx_id) AS c2 FROM tx_event_tag GROUP BY event_code ORDER BY event_code',[[f'E{i}',n] for i,n in enumerate([1,13,18,5,6,4,3,1,2],1)],'Distinct logical changes per tag, including multiple tags per change.')
union=' UNION ALL '.join(f"SELECT '{t}' AS source_table,tx_id,tx_from,tx_to FROM {t}" for t in ['club_version','contract_version','head_coach_role_version'])
add('e1_versions',f"SELECT u.source_table AS c1,COUNT(*) AS c2 FROM ({union}) u JOIN tx_registry r ON r.tx_id=u.tx_id WHERE LEFT(r.reason,3)='T01' GROUP BY u.source_table ORDER BY u.source_table",[['club_version',6],['contract_version',60],['head_coach_role_version',7]],'E1 produces exactly 73 versions, including two adjacent CL04 tenures.')
for inv in ['I1','I2','I3']:
    count(inv,'v_integrity_violations',0,f"invariant_code='{inv}'",'Final Q0 must report no violations.')
count('q0_all','v_integrity_violations',0)
add('registry_times',f"SELECT COUNT(*) AS c1 FROM ({union}) u LEFT JOIN tx_registry r ON r.tx_id=u.tx_id WHERE r.tx_id IS NULL OR u.tx_from<>r.tx_time OR (u.tx_to<>'{INF}' AND NOT EXISTS (SELECT 1 FROM tx_registry z WHERE z.tx_time=u.tx_to))",[[0]],'Each opening and finite closing refers to a registered change; does not claim to prove I4.')
roles='FROM head_coach_role_version v JOIN head_coach_role a ON a.role_id=v.role_id JOIN club c ON c.club_id=a.club_id JOIN coach h ON h.coach_id=v.coach_id'
contracts='FROM contract_version v JOIN contract a ON a.contract_id=v.contract_id JOIN player p ON p.player_id=a.player_id JOIN club c ON c.club_id=a.club_id'
def role(id,valid,known,code):
    add(id,f"SELECT h.coach_code AS c1,h.full_name AS c2 {roles} WHERE c.club_code='CL01' AND {snap(valid,known)} ORDER BY h.coach_code",[[code,names[int(code[1:])-1]]],'CL01 A → B → A; half-open VT and TT.',dict(valid_at=valid,known_at=known,club_code='CL01'))
for id,k,h in [('perspective_1','2026-03-05 12:00:00.000000','H01'),('perspective_2','2026-03-12 12:00:00.000000','H02'),('perspective_3','2026-03-16 12:00:00.000000','H01'),('t18_before','2026-03-10 13:59:59.999999','H01'),('t18_exact','2026-03-10 14:00:00.000000','H02'),('t18_after','2026-03-10 14:00:00.000001','H02'),('t19_before','2026-03-15 10:59:59.999999','H02'),('t19_exact','2026-03-15 11:00:00.000000','H01'),('t19_after','2026-03-15 11:00:00.000001','H01')]: role(id,'2026-03-02',k,h)
role('cl01_vt_boundary','2026-03-03',KNOWN,'H02')
add('cl01_five_versions',f"SELECT h.coach_code AS c1,v.valid_from AS c2,v.valid_to AS c3,LEFT(r.reason,3) AS c4,DATE_FORMAT(v.tx_to,'%Y-%m-%d %H:%i:%s.%f') AS c5 {roles} JOIN tx_registry r ON r.tx_id=v.tx_id WHERE c.club_code='CL01' ORDER BY v.tx_from,v.valid_from",[
 ['H01','2025-07-01','9999-12-31','T01','2026-03-10 14:00:00.000000'],['H01','2025-07-01','2026-03-01','T18','2026-03-15 11:00:00.000000'],['H02','2026-03-01','9999-12-31','T18','2026-03-15 11:00:00.000000'],['H01','2025-07-01','2026-03-03','T19',INF],['H02','2026-03-03','9999-12-31','T19',INF]],'Five preserved beliefs; T19 corrects both boundaries.')
add('cl04_raw',f"SELECT h.coach_code AS c1,v.valid_from AS c2,v.valid_to AS c3 {roles} WHERE c.club_code='CL04' AND v.tx_to='{INF}' ORDER BY v.valid_from",[['H05','2025-07-01','2026-07-01'],['H05','2026-07-01','9999-12-31']],'Two current rows, same coach, adjacent seasons.')
add('cl04_coalesced',f"""WITH s AS (SELECT h.coach_code,v.valid_from,v.valid_to,MAX(v.valid_to) OVER (PARTITION BY h.coach_code ORDER BY v.valid_from ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_end {roles} WHERE c.club_code='CL04' AND v.tx_to='{INF}'), m AS (SELECT *,SUM(CASE WHEN prior_end IS NULL OR prior_end<valid_from THEN 1 ELSE 0 END) OVER (PARTITION BY coach_code ORDER BY valid_from) AS island FROM s) SELECT coach_code AS c1,MIN(valid_from) AS c2,MAX(valid_to) AS c3 FROM m GROUP BY coach_code,island ORDER BY c1,c2""",[['H05','2025-07-01','9999-12-31']],'Running endpoint coalescing merges adjacency, not DISTINCT.')
def contract_snapshot(id,p,c,v,k,rows):
    add(id,f"SELECT c.club_code AS c1,v.agreement_kind AS c2,v.salary_eur AS c3 {contracts} WHERE p.player_code='{p}'"+(f" AND c.club_code='{c}'" if c else '')+f" AND {snap(v,k)} ORDER BY c.club_code,v.valid_from",rows,'Literal as-of result from section 9; empty rows mean absence.',dict(player_code=p,club_code=c,valid_at=v,known_at=k))
contract_snapshot('p001_before','P001',None,'2025-09-01','2025-09-05 12:00:00',[['CL01','PERMANENT','1010.00']])
contract_snapshot('p001_after','P001',None,'2025-09-01','2025-09-12 12:00:00',[['CL06','PERMANENT','1510.00']])
contract_snapshot('p001_transfer_boundary','P001',None,'2025-08-31',KNOWN,[['CL06','PERMANENT','1510.00']])
for id,k,rows in [('loan_before','2026-06-12 12:00:00',[['CL02','LOAN','600.00']]),('loan_after','2026-07-06 12:00:00',[])]: contract_snapshot(id,'P006','CL02','2026-07-15',k,rows)
for id,k,rows in [('retract_before','2026-04-12 12:00:00',[['CL06','LOAN','600.00']]),('retract_after','2026-04-26 12:00:00',[])]: contract_snapshot(id,'P060','CL06','2026-04-15',k,rows)
for id,k,s in [('salary_before','2026-05-06 12:00:00','1450.00'),('salary_after','2026-05-11 12:00:00','1455.00')]: contract_snapshot(id,'P025','CL03','2026-05-05',k,[['CL03','PERMANENT',s]])
for v,b in [('2026-10-15','1500000.00'),('2026-11-01','1650000.00')]:
    add('cl06_budget_'+v,f"SELECT v.budget_eur AS c1 FROM club_version v JOIN club c ON c.club_id=v.club_id WHERE c.club_code='CL06' AND {snap(v,KNOWN)}",[[b]],'T37 is known before November; prefix preserved.',dict(valid_at=v,known_at=KNOWN))
add('cl06_zero_july',f"SELECT COUNT(*) AS c1 {contracts} WHERE c.club_code='CL06' AND v.tx_to='{INF}' AND v.valid_from<'2025-08-01' AND '2025-07-01'<v.valid_to",[[0]],'Zero contracts overlapping all of July, including loans.')
add('cl06_exists_july',f"SELECT COUNT(*) AS c1 FROM club_version v JOIN club c ON c.club_id=v.club_id WHERE c.club_code='CL06' AND v.tx_to='{INF}' AND v.valid_from<='2025-07-01' AND v.valid_to>='2025-08-01'",[[1]],'The empty month belongs to an existing club.')
add('overlap_containment',f"SELECT p.player_code AS c1,c.club_code AS c2,(v.valid_from<'2026-07-01' AND '2025-07-01'<v.valid_to) AS c3,(v.valid_from<='2025-07-01' AND '2026-07-01'<=v.valid_to) AS c4 {contracts} WHERE v.tx_to='{INF}' AND ((p.player_code='P018' AND c.club_code='CL02') OR (p.player_code='P001' AND c.club_code='CL06')) ORDER BY c1",[['P001','CL06',1,0],['P018','CL02',1,1]],'Q4 overlap and containment are different predicates.')
add('gaps',f"""WITH s AS (SELECT p.player_code,c.club_code,v.valid_from,MAX(v.valid_to) OVER (PARTITION BY a.contract_id ORDER BY v.valid_from,v.version_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_end {contracts} WHERE v.tx_to='{INF}') SELECT player_code AS c1,club_code AS c2,prior_end AS c3,valid_from AS c4,DATEDIFF(valid_from,prior_end) AS c5 FROM s WHERE prior_end<valid_from ORDER BY player_code,club_code,valid_from""",[['P006','CL02','2026-07-01','2026-10-01',92],['P013','CL02','2025-12-01','2026-02-01',62],['P014','CL02','2025-12-15','2026-03-01',76],['P015','CL02','2025-12-20','2026-03-10',80]],'All four gaps, same anchor; adjacent salary slices excluded.')
for player,club,rows in [('P006','CL02',[
 ['2026-06-01','2026-09-01','600.00','T28','2026-07-05 10:00:00.000000'],['2026-06-01','2026-07-01','600.00','T32',INF],['2026-10-01','2026-12-01','650.00','T38',INF]]),('P060','CL06', [['2026-04-01','2026-05-01','600.00','T21','2026-04-25 10:00:00.000000']])]:
    add('history_'+player,f"SELECT v.valid_from AS c1,v.valid_to AS c2,v.salary_eur AS c3,LEFT(r.reason,3) AS c4,DATE_FORMAT(v.tx_to,'%Y-%m-%d %H:%i:%s.%f') AS c5 {contracts} JOIN tx_registry r ON r.tx_id=v.tx_id WHERE p.player_code='{player}' AND c.club_code='{club}' ORDER BY v.tx_from,v.valid_from",rows,'History remains intact; finite TT is not finite VT.')
add('t25_no_replacement',f"SELECT COUNT(*) AS c1 FROM ({union}) u JOIN tx_registry r ON r.tx_id=u.tx_id WHERE LEFT(r.reason,3)='T25'",[[0]],'Retracting transaction has no new versions in any business table.')
add('two_season_fact',f"SELECT p.player_code AS c1,c.club_code AS c2,v.valid_from AS c3,v.valid_to AS c4 {contracts} WHERE p.player_code='P018' AND c.club_code='CL02' AND v.tx_to='{INF}'",[['P018','CL02','2025-07-01','9999-12-31']],'Actual relationship spans both seasons, exceeding twelve months.')
add('adjacent_parent_union',f"""SELECT c.club_code AS c1,v.valid_from AS c2,v.valid_to AS c3 FROM club_version v JOIN club c ON c.club_id=v.club_id WHERE c.club_code='CL02' AND v.tx_to='{INF}' ORDER BY v.valid_from""",[['CL02','2025-07-01','2025-12-01'],['CL02','2025-12-01','9999-12-31']],'Together cover P018 contract; neither individually covers it.')
add('no_single_parent',f"SELECT COUNT(*) AS c1 {contracts} WHERE p.player_code='P018' AND c.club_code='CL02' AND v.tx_to='{INF}' AND EXISTS(SELECT 1 FROM club_version b WHERE b.club_id=c.club_id AND b.tx_to='{INF}' AND b.valid_from<=v.valid_from AND v.valid_to<=b.valid_to)",[[0]],'I2 succeeds through the adjacent union, not a single covering parent.')
club_names = ['FC Someș','FC Ardeal','FC Mureș','FC Apuseni','FC Criș','FC Târnava']
add('e1_club_values', "SELECT c.club_code AS c1,v.club_name AS c2,v.budget_eur AS c3,v.valid_from AS c4,v.valid_to AS c5 FROM club_version v JOIN club c ON c.club_id=v.club_id JOIN tx_registry r ON r.tx_id=v.tx_id WHERE LEFT(r.reason,3)='T01' ORDER BY c.club_code", [[f'CL{i:02}',n,f'{900000+100000*i}.00','2025-07-01','9999-12-31'] for i,n in enumerate(club_names,1)], 'Six literal initial names and budgets, retained in history.')
add('e1_contract_values', f"SELECT p.player_code AS c1,c.club_code AS c2,v.agreement_kind AS c3,v.salary_eur AS c4,v.valid_from AS c5,v.valid_to AS c6 {contracts} JOIN tx_registry r ON r.tx_id=v.tx_id WHERE LEFT(r.reason,3)='T01' ORDER BY p.player_code", [[f'P{i:03}',f'CL{(i-1)//12+1:02}','PERMANENT',f'{1000+10*i}.00','2025-07-01','9999-12-31'] for i in range(1,61)], 'Initial distribution and salary formula from section 4, before later changes.')
add('e1_role_values', f"SELECT c.club_code AS c1,h.coach_code AS c2,v.valid_from AS c3,v.valid_to AS c4 {roles} JOIN tx_registry r ON r.tx_id=v.tx_id WHERE LEFT(r.reason,3)='T01' ORDER BY c.club_code,v.valid_from", [['CL01','H01','2025-07-01','9999-12-31'],['CL02','H03','2025-07-01','9999-12-31'],['CL03','H04','2025-07-01','9999-12-31'],['CL04','H05','2025-07-01','2026-07-01'],['CL04','H05','2026-07-01','9999-12-31'],['CL05','H06','2025-07-01','9999-12-31'],['CL06','H07','2025-07-01','9999-12-31']], 'Seven original role assertions, not seven changes of coach.')
for valid,n in [('2026-09-21',58),('2026-10-15',59)]:
    add('active_contracts_'+valid,f"SELECT COUNT(*) AS c1,COUNT(DISTINCT v.contract_id) AS c2 {contracts} WHERE {snap(valid,KNOWN)}",[[n,n]],'60 initial permanent relations, transfers preserve total, two ended without restart; October adds restarted P006 loan.',dict(valid_at=valid,known_at=KNOWN))
# Artifacts are deterministic and independent from the generated data/replay implementation.
out={'description':'Expected literals from phase-2 user plan sections 4, 6, 8 and 9. No actual database results used. All SQL is standalone SELECT/WITH, columns in expected order, batch strings. SQL audit compares exact row multiplicities; JSON runner also checks ORDER BY output.', 'params':{'known_at_final':KNOWN,'valid_at':'2026-03-02','known_at':'2026-03-16 12:00:00.000000','period_start':'2025-07-01','period_end':'2026-07-01','subject_code':'CL01','subject_id_resolution':"SELECT club_id FROM club WHERE club_code='CL01'"},'cases':cases}
(ROOT/'docs/expected_results.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
def literal(s): return "'"+s.replace("'","''")+"'"
lines=['-- Generated by scripts/build_dataset_assertions.py from independent plan literals.', '-- Final audit: no business DML, no persistent procedures, no database selection.', '-- Run standalone after 01 -> 02 -> 03 with mariadb --batch (never --force).', '-- Requires CREATE TEMPORARY TABLES. On error close the session; SIGNAL is fatal.', '-- Do not run concurrently with replay. No COMMIT/ROLLBACK of caller transactions.', 'SET NAMES utf8mb4;', "SET SESSION time_zone = '+00:00';", 'DELIMITER $$', 'BEGIN NOT ATOMIC', '  DECLARE EXIT HANDLER FOR SQLEXCEPTION', '  BEGIN', '    DROP TEMPORARY TABLE IF EXISTS tc_dataset_actual;', '    RESIGNAL;', '  END;']
for c in cases:
    lines += ['  -- '+c['id']+': '+c['reason'], '  CREATE TEMPORARY TABLE tc_dataset_actual AS '+c['sql']+';']
    terms=[f'(SELECT COUNT(*) FROM tc_dataset_actual) <> {len(c["expected"])}']
    for row,multiplicity in Counter(tuple(r) for r in c['expected']).items():
        pred=' AND '.join(f'BINARY CAST(c{i} AS CHAR) <=> BINARY {literal(s)}' for i,s in enumerate(row,1))
        terms.append(f'(SELECT COUNT(*) FROM tc_dataset_actual WHERE {pred}) <> {multiplicity}')
    lines += ['  IF '+'\n     OR '.join(terms)+' THEN',f"    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TC_DATASET: {c['id']}';", '  END IF;', '  DROP TEMPORARY TABLE tc_dataset_actual;']
lines += [f"  SELECT 'PASS' AS result, {len(cases)} AS dataset_cases;", 'END$$','DELIMITER ;','']
(ROOT/'tests/03_dataset_assertions.sql').write_text('\n'.join(lines))
print(f'Generated {len(cases)} independent cases; no DB connection.')
