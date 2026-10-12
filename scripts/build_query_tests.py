#!/usr/bin/env python3
"""Author Part C expectations and standalone SQL; never connects to a database.
Uses only the independent literal-history model prefix from the phase-2 assertion
helper, never its SQL emitter or the data/view generators. Existing files untouched.
Runtime 05_tests.sql has no Python, SOURCE, routine, or permanent DDL dependency.
"""
from pathlib import Path
from datetime import date, datetime, timedelta
from collections import Counter
import json
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'scripts/build_timeline_assertions.py').read_text()
model={}
exec(compile(source.split('\nout=[]\n',1)[0], 'literal_history_model', 'exec'),model)
H=model['rows']; EVENTS=model['events']; INF=model['END']; TT=model['INF']
PLAN=json.loads((ROOT/'docs/timeline_plan.json').read_text())
assert len(H)==131 and sum(r['kind']=='contract' and r['close'] is None for r in H)==77
CURRENT=[r for r in H if r['close'] is None]
def q(x): return 'NULL' if x is None else "'"+str(x).replace("'","''")+"'"
def ts(n): return EVENTS[n][1] if n is not None else TT
def fmt(n): return f'{n:.2f}'
def contract_row(r):
 p,c=r['key'].split('/')
 return [p,c,r['value'],fmt(r['amount']),r['start'],r['end'],ts(r['tx']),ts(r['close'])]
def asof(k): return [r for r in H if r['kind']=='contract' and ts(r['tx'])<=k<ts(r['close'])]
BASE=dict(valid_at='2026-03-02',known_at='2026-09-21 12:00:00.000000',period_start='2025-07-01',period_end='2026-07-01',subject_kind='club',subject_code='CL01')
CASES=[]
def add(id,sql,rows,reason,params=None,capture=None,expected_sql=None):
 c=dict(id=id,sql=sql,expected=None if rows is None else [[None if v is None else str(v) for v in r] for r in rows],reason=reason,params={**BASE,**(params or {})},capture_sql=capture or sql)
 if expected_sql:c['expected_sql']=expected_sql
 CASES.append(c)
def cols(exprs):return ','.join(f'{e} AS c{i}' for i,e in enumerate(exprs,1))
C=['player_code','club_code','agreement_kind','salary_eur','valid_from','valid_to',"DATE_FORMAT(tx_from,'%Y-%m-%d %H:%i:%s.%f')","DATE_FORMAT(tx_to,'%Y-%m-%d %H:%i:%s.%f')"]
add('Q0_clean','SELECT COUNT(*) AS c1 FROM v_integrity_violations',[[0]],'Final dataset has no I1-I3 violations.',capture='SELECT COUNT(*) AS violation_count FROM v_integrity_violations;\nSELECT * FROM v_integrity_violations ORDER BY invariant_code,source_table,business_key,version_id')
# Dynamic expectations use literal periods, evaluated with the same actual UTC day.
p6=[r for r in CURRENT if r['kind']=='contract' and r['key'].startswith('P006/')]
literal=' UNION ALL '.join('SELECT '+','.join(f'{q(v)} AS c{i}' for i,v in enumerate(contract_row(r),1)) for r in p6)
add('Q1_today_P006','SELECT '+cols(C)+' FROM v_q1_current_contracts ORDER BY player_code,club_code,valid_from',None,'Real UTC_DATE(), permanent plus any active literal loan period; no simulated clock.',dict(subject_kind='player',subject_code='P006'),capture='SELECT * FROM v_q1_current_contracts ORDER BY club_code,valid_from',expected_sql=f'SELECT * FROM ({literal}) literals WHERE c5<=UTC_DATE() AND UTC_DATE()<c6 ORDER BY c2,c5')
# Further Q1 metadata checked once columns are final.
for club in ['CL01','CL03','CL04']:
 rr=sorted([r for r in CURRENT if r['kind']=='role' and r['key']==club],key=lambda r:r['start'])
 tenures=[]
 for r in rr:
  if tenures and tenures[-1][0]==r['value'] and tenures[-1][2]==r['start']:tenures[-1][2]=r['end']
  else:tenures.append([r['value'],r['start'],r['end']])
 expressions=[]
 for coach,start,end in tenures:
  days=None if end==INF else (date.fromisoformat(end)-date.fromisoformat(start)).days
  expressions.append('SELECT '+cols([q(club),q(coach),q(start),q(end),q(days),f'GREATEST(DATEDIFF(LEAST(UTC_DATE(),{q(end)}),{q(start)}),0)',f"CASE WHEN UTC_DATE()<{q(start)} THEN 'SCHEDULED' WHEN UTC_DATE()>={q(end)} THEN 'ENDED' ELSE 'ACTIVE' END"]))
 add('Q2_today_'+club,'SELECT '+cols(['club_code','coach_code','tenure_from','tenure_to','tenure_days','elapsed_days','tenure_status'])+' FROM v_q2_coach_tenures ORDER BY tenure_from',None,'Current belief only; merge adjacent same holder, finite/open durations and actual UTC status.',dict(subject_code=club),capture='SELECT * FROM v_q2_coach_tenures ORDER BY tenure_from,coach_code',expected_sql=' UNION ALL '.join(expressions))
# Q3 full component identities and all signed dates/categories. Detail arrays added below.
audit=[]
for e in PLAN:
 tags=e['event_tags']
 if not set(tags)&{'E2','E3','E4'}:continue
 families=['CLUB','CONTRACT'] if e['primary_operation']=='multi' else ['HEAD_COACH' if e['primary_operation'].startswith('role') else 'CLUB' if e['primary_operation']=='budget' else 'CONTRACT']
 for family in families:
  audit.append([e['event_ref'],family,e['p'] if family=='CONTRACT' else e['club'],e['tx_time_utc'],','.join(tags),int('E2'in tags),int('E3'in tags),int('E4'in tags),e['effective_from'],e['delay_days'],max(-e['delay_days'],0)])
assert len(audit)==33 and len({r[0] for r in audit})==31
add('Q3_all_events','SELECT '+cols(['event_ref','fact_family','subject_code',"DATE_FORMAT(tx_time,'%Y-%m-%d %H:%i:%s.%f')",'event_codes','is_proactive','is_late','is_correction','effective_date','delay_days','lead_days'])+' FROM v_q3_event_audit ORDER BY event_ref,fact_family,subject_code',sorted(audit),'All 31 authored events,33 components; categories coexist; dates from semantic event plan.',capture='SELECT * FROM v_q3_event_audit ORDER BY tx_time,fact_family,subject_code')
add('Q3_distinct_counts','SELECT COUNT(*) AS c1,COUNT(DISTINCT tx_id) AS c2,COUNT(DISTINCT CASE WHEN is_proactive=1 THEN tx_id END) AS c3,COUNT(DISTINCT CASE WHEN is_late=1 THEN tx_id END) AS c4,COUNT(DISTINCT CASE WHEN is_correction=1 THEN tx_id END) AS c5 FROM v_q3_event_audit',[[33,31,13,18,5]],'Distinct event counts independent of components.')
add('Q3_unique_registry_times','SELECT COUNT(*) AS c1,COUNT(DISTINCT tx_time) AS c2 FROM tx_registry',[[38,38]],'Validate timestamp disambiguation precondition; no added UNIQUE constraint.')
# All 77 current facts, not just the illustrative pair. Exactly equal endpoints too.
for id,start,end in [('season1','2025-07-01','2026-07-01'),('season2','2026-07-01','2027-07-01'),('exact_loan','2026-06-01','2026-07-01'),('touch_loan','2026-07-01','2026-10-01')]:
 rr=[contract_row(r)+[int(r['start']<end and start<r['end']),int(r['start']<=start and end<=r['end'])] for r in CURRENT if r['kind']=='contract']
 add('Q4_'+id,'SELECT '+cols(C+['at_some_point','throughout'])+' FROM v_q4_period_relationships ORDER BY player_code,club_code,valid_from',sorted(rr),'Fact-level strict overlap and exact containment; salary slices remain separate.',dict(period_start=start,period_end=end,subject_kind='player',subject_code='P060'),capture='SELECT * FROM v_q4_period_relationships ORDER BY player_code,club_code,valid_from')
for id,k,v,p in [('final','2026-09-21 12:00:00.000000','2026-03-02','CL01'),('ignore_valid_subject','2026-09-21 12:00:00.000000','1900-01-01','CL06'),('before_T21','2026-04-10 13:59:59.999999','2026-04-15','CL01'),('at_T21','2026-04-10 14:00:00.000000','2026-04-15','CL01'),('before_T25','2026-04-25 09:59:59.999999','2026-04-15','CL01'),('at_T25','2026-04-25 10:00:00.000000','2026-04-15','CL01')]:
 add('Q5_'+id,'SELECT '+cols(C)+' FROM v_q5_contracts_as_known ORDER BY player_code,club_code,valid_from',sorted(contract_row(r) for r in asof(k)),'Full known-at table, including finite past and known future facts.',dict(known_at=k,valid_at=v,subject_code=p),capture='SELECT * FROM v_q5_contracts_as_known ORDER BY player_code,club_code,valid_from')
# Q6 all families per point: detect multiplication and erroneous cross-branch filters.
def q6(id,club,v,k):
 rows=[]
 for r in H:
  if not (r['start']<=v<r['end'] and ts(r['tx'])<=k<ts(r['close'])):continue
  if r['kind']=='role' and r['key']==club:rows.append(['HEAD_COACH',club,r['value'],None,None,r['start'],r['end'],ts(r['tx']),ts(r['close'])])
  if r['kind']=='contract' and r['key'].endswith('/'+club):rows.append(['CONTRACT',club,r['key'].split('/')[0],r['value'],fmt(r['amount']),r['start'],r['end'],ts(r['tx']),ts(r['close'])])
 add('Q6_'+id,'SELECT '+cols(['fact_kind','club_code','subject_code','agreement_kind','salary_eur','valid_from','valid_to',"DATE_FORMAT(tx_from,'%Y-%m-%d %H:%i:%s.%f')","DATE_FORMAT(tx_to,'%Y-%m-%d %H:%i:%s.%f')"])+ ' FROM v_q6_bitemporal_point ORDER BY fact_kind,subject_code,valid_from',sorted(rows),'Both branches compared in full against authored physical history; half-open VT and TT.',dict(subject_code=club,valid_at=v,known_at=k),capture='SELECT * FROM v_q6_bitemporal_point ORDER BY fact_kind,subject_code,valid_from')
for n,k in enumerate(['2026-03-05 12:00:00.000000','2026-03-12 12:00:00.000000','2026-03-16 12:00:00.000000'],1):q6('perspective_'+str(n),'CL01','2026-03-02',k)
for event in [18,19]:
 t=datetime.fromisoformat(ts(event))
 for delta,label in [(-1,'before'),(0,'exact'),(1,'after')]:q6(f'T{event}_{label}','CL01','2026-03-02',(t+timedelta(microseconds=delta)).isoformat(' ',timespec='microseconds'))
for v in ['2026-02-28','2026-03-01','2026-03-02','2026-03-03','2026-03-04']:
 for label,k in [('initial','2026-03-12 12:00:00.000000'),('corrected',BASE['known_at'])]:q6('VT_'+v+'_'+label,'CL01',v,k)
for label,club,v,k in [('transfer_old','CL01','2025-09-01','2025-09-05 12:00:00.000000'),('transfer_new','CL06','2025-09-01','2025-09-12 12:00:00.000000'),('transfer_boundary','CL06','2025-08-31',BASE['known_at']),('loan_before','CL02','2026-07-15','2026-06-12 12:00:00.000000'),('loan_after','CL02','2026-07-15','2026-07-06 12:00:00.000000'),('retract_before','CL06','2026-04-15','2026-04-12 12:00:00.000000'),('retract_after','CL06','2026-04-15','2026-04-26 12:00:00.000000'),('salary_before','CL03','2026-05-05','2026-05-06 12:00:00.000000'),('salary_after','CL03','2026-05-05','2026-05-11 12:00:00.000000')]:q6(label,club,v,k)
# Literal prompt matrix cross-checked against independent history (not view output).
matrix=[[12,12,12,12,12,0],[12,13,13,13,13,1]]+[[7,13,13,13,13,1]]*3+[[7,12,13,13,13,1],[7,9,13,13,13,1],[7,9,13,13,13,1]]+[[7,11,13,13,13,1]]*3+[[7,12,14,14,13,1]]
def next_month(s):
 d=date.fromisoformat(s);return date(d.year+(d.month==12),1 if d.month==12 else d.month+1,1).isoformat()
def monthly(start,end):
 m=start[:8]+'01';rows=[]
 while m<end:
  nxt=next_month(m);lo=max(start,m);hi=min(end,nxt)
  for c in range(1,7):
   club=f'CL{c:02}'
   keys={r['key'] for r in CURRENT if r['kind']=='contract' and r['key'].endswith('/'+club) and r['start']<hi and lo<r['end']}
   rows.append([m,club,lo,hi,len(keys)])
  m=nxt
 return rows
mrows=monthly('2025-07-01','2026-07-01')
assert [r[-1] for r in mrows]==[v for row in matrix for v in row]
for id,start,end in [('season1','2025-07-01','2026-07-01'),('season2','2026-07-01','2027-07-01'),('partial','2026-06-15','2026-07-15'),('one_day','2025-08-30','2025-08-31')]:
 add('Q7_'+id,'SELECT '+cols(['month_start','club_code','window_start','window_end','relationship_count'])+' FROM v_q7_monthly_relationships ORDER BY month_start,club_code',monthly(start,end),'Calendar × all clubs; distinct pair intersections from literal current history; cropped endpoints.',dict(period_start=start,period_end=end,subject_kind='player',subject_code='P060'),capture='SELECT * FROM v_q7_monthly_relationships ORDER BY month_start,club_code')
gaps=[['P006','CL02','2026-07-01','2026-10-01',92],['P013','CL02','2025-12-01','2026-02-01',62],['P014','CL02','2025-12-15','2026-03-01',76],['P015','CL02','2025-12-20','2026-03-10',80]]
add('Q8_all_gaps','SELECT '+cols(['player_code','club_code','gap_from','gap_to','gap_days'])+' FROM v_q8_relationship_gaps ORDER BY player_code,club_code,gap_from',gaps,'Exactly four E6 gaps; salary adjacency must not become gaps.',dict(subject_kind='player',subject_code='P060'),capture='SELECT * FROM v_q8_relationship_gaps ORDER BY player_code,club_code,gap_from')
# Audit every old/new row per component, independently of SQL views.
audit_details=[]
for entry in audit:
 ref,family,subject=entry[:3];n=int(ref[1:]);kind={'CLUB':'club','CONTRACT':'contract','HEAD_COACH':'role'}[family]
 def relevant(r):return r['kind']==kind and (r['key'].split('/')[0] if kind=='contract' else r['key'])==subject
 def objects(rs):
  return [dict(business_key=r['key'],value=r['value'] if kind=='role' else fmt(r['amount']),agreement_kind=r['value'] if kind=='contract' else None,valid_from=r['start'],valid_to=r['end']) for r in sorted(rs,key=lambda r:(r['key'],r['start']))]
 old=objects([r for r in H if relevant(r) and r['close']==n]);new=objects([r for r in H if relevant(r) and r['tx']==n])
 compact=lambda a:json.dumps(a,ensure_ascii=False,separators=(',',':')) if a else None
 audit_details.append([ref,family,subject,compact(old),compact(new),0])
add('Q3_all_old_new','SELECT event_ref AS c1,fact_family AS c2,subject_code AS c3,JSON_COMPACT(old_values) AS c4,JSON_COMPACT(new_values) AS c5,ambiguous_closure AS c6 FROM v_q3_event_audit ORDER BY event_ref,fact_family,subject_code',sorted(audit_details),'All old/new values and intervals from independent literal history, including prefixes and corrected frontiers.')
# Materialize complete expected file, no database reads.
(ROOT/'docs/query_expected_results.json').write_text(json.dumps({'source':'Literal timeline simulation plus prompt matrix; never copied from views','cases':CASES},ensure_ascii=False,indent=2)+'\n')
out=['''-- Part C entry point; standalone MariaDB CLI, DELIMITER aware. Fresh session required.
-- Default: only query_params is changed and restored. Negative fixtures require both gates.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET time_zone='+00:00';
DELIMITER $$
BEGIN NOT ATOMIC
 DECLARE sv DATE; DECLARE sk DATETIME(6); DECLARE ss DATE; DECLARE se DATE; DECLARE sid BIGINT UNSIGNED;
 DECLARE saved BOOLEAN DEFAULT FALSE; DECLARE checks INT DEFAULT 0; DECLARE scenario VARCHAR(128) DEFAULT 'preflight';
 DECLARE err TEXT; DECLARE eno INT;
 DECLARE xclub BIGINT UNSIGNED; DECLARE xcontract BIGINT UNSIGNED; DECLARE xrole BIGINT UNSIGNED;
 DECLARE xtx BIGINT UNSIGNED; DECLARE xv BIGINT UNSIGNED; DECLARE xv2 BIGINT UNSIGNED;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 eno=MYSQL_ERRNO,err=MESSAGE_TEXT;
  ROLLBACK;
  IF saved THEN UPDATE query_params SET valid_at=sv,known_at=sk,period_start=ss,period_end=se,subject_id=sid WHERE params_id=1; END IF;
  SET @sim_now=NULL,@write_tx_id=NULL;
  SELECT scenario AS failed_scenario,eno AS error_code,err AS error_message;
  RESIGNAL;
 END;
 IF @@in_transaction THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P3_SESSION: fresh session required'; END IF;
 IF COALESCE(@p3_negative,0)<>0 AND (COALESCE(@p3_negative,0)<>1 OR DATABASE()='two_clocks_cabd'
 OR DATABASE() NOT REGEXP '^two_clocks_cabd_verify_p3_[a-zA-Z0-9_]+$'
 OR NOT (BINARY DATABASE() <=> BINARY @p3_test_database)) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P3_GUARD: negative fixtures require runner-created matching test database'; END IF;
 IF (SELECT COUNT(*) FROM query_params)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P3_PARAMS: singleton missing'; END IF;
 SELECT valid_at,known_at,period_start,period_end,subject_id INTO sv,sk,ss,se,sid FROM query_params WHERE params_id=1;
 SET saved=TRUE;
 IF (SELECT COUNT(*) FROM tx_registry)<>(SELECT COUNT(DISTINCT tx_time) FROM tx_registry) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P3_AUDIT: ambiguous closing times'; END IF;
''']
for c in CASES:
 id=c['id'];par=c['params'];sql=c['sql'];expected=c.get('expected_sql')
 count=len(c['expected'][0]) if c['expected'] else (8 if id.startswith('Q1') else 7)
 if c['expected'] is not None and not c['expected']:raise RuntimeError('unexpected empty oracle')
 names=[f'c{i}' for i in range(1,count+1)]
 out+= [f"SET scenario={q(id)};",f"UPDATE query_params SET valid_at={q(par['valid_at'])},known_at={q(par['known_at'])},period_start={q(par['period_start'])},period_end={q(par['period_end'])},subject_id=(SELECT {par['subject_kind']}_id FROM {par['subject_kind']} WHERE {par['subject_kind']}_code={q(par['subject_code'])}) WHERE params_id=1;",
 'DROP TEMPORARY TABLE IF EXISTS p3_expected;','DROP TEMPORARY TABLE IF EXISTS p3_actual;',
 'CREATE TEMPORARY TABLE p3_expected ('+','.join(n+' LONGTEXT COLLATE utf8mb4_unicode_ci' for n in names)+');',
 'CREATE TEMPORARY TABLE p3_actual LIKE p3_expected;']
 if expected:out+=['INSERT INTO p3_expected '+expected+';']
 else:out+=['INSERT INTO p3_expected VALUES '+','.join('('+','.join(q(v) for v in r)+')' for r in c['expected'])+';']
 out+=['INSERT INTO p3_actual '+sql+';',
 'IF (SELECT COUNT(*) FROM p3_actual)<>(SELECT COUNT(*) FROM p3_expected) OR EXISTS(SELECT 1 FROM p3_expected e WHERE (SELECT COUNT(*) FROM p3_actual a WHERE '+ ' AND '.join(f'(BINARY a.{n} <=> BINARY e.{n})' for n in names)+")<>1) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=scenario; END IF;",
 'SET checks=checks+1;',"IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P3_Q0: positive scenario contaminated'; END IF;",
 f"SELECT 'P3_RESULT_BEGIN:{id}' AS p3_marker;",'SELECT * FROM query_params;',c['capture_sql']+';',f"SELECT 'P3_RESULT_END:{id}' AS p3_marker;"]
out+=['''
 IF COALESCE(@p3_negative,0)=1 THEN
  SET scenario='Q0_negative_I1';
  START TRANSACTION;
  SET @sim_now=NULL;
  INSERT INTO tx_registry(tx_time,author,reason) VALUES(fn_effective_time(),'Part C test','Q0 I1 fixture rollback');
  SET xtx=LAST_INSERT_ID();
  INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id)
  SELECT v.contract_id,v.agreement_kind,v.salary_eur,v.valid_from,v.valid_to,r.tx_time,xtx FROM contract_version v
  JOIN contract a USING(contract_id) JOIN player p USING(player_id) JOIN tx_registry r ON r.tx_id=xtx
  WHERE p.player_code='P018' AND v.tx_to='9999-12-31 23:59:59.999999';
  SET xv=LAST_INSERT_ID();
  IF (SELECT COUNT(*) FROM v_integrity_violations WHERE invariant_code='I1' AND source_table='contract_version' AND (version_id=xv OR conflicting_version_id=xv))<>1
  OR (SELECT COUNT(*) FROM v_integrity_violations)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Q0 I1 exact diagnosis missing'; END IF;
  SELECT 'P3_RESULT_BEGIN:Q0_negative_I1' AS p3_marker; SELECT * FROM query_params; SELECT * FROM v_integrity_violations; SELECT 'P3_RESULT_END:Q0_negative_I1' AS p3_marker;
  ROLLBACK; SET checks=checks+1;
  IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Q0 after I1 rollback'; END IF;

  SET scenario='Q0_negative_I3'; START TRANSACTION;
  INSERT INTO tx_registry(tx_time,author,reason) VALUES(fn_effective_time(),'Part C test','Q0 I3 fixture rollback'); SET xtx=LAST_INSERT_ID();
  INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id)
  SELECT a.role_id,h.coach_id,'2026-04-01','2026-04-02',r.tx_time,xtx FROM head_coach_role a JOIN club c USING(club_id)
  CROSS JOIN coach h JOIN tx_registry r ON r.tx_id=xtx WHERE c.club_code='CL01' AND h.coach_code='H08';
  SET xv=LAST_INSERT_ID();
  IF (SELECT COUNT(*) FROM v_integrity_violations WHERE invariant_code='I3' AND (version_id=xv OR conflicting_version_id=xv))<>1
  OR (SELECT COUNT(*) FROM v_integrity_violations WHERE invariant_code='I1' AND source_table='head_coach_role_version')<>1
  OR (SELECT COUNT(*) FROM v_integrity_violations)<>2 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Q0 I3 exact diagnosis missing'; END IF;
  SELECT 'P3_RESULT_BEGIN:Q0_negative_I3' AS p3_marker; SELECT * FROM query_params; SELECT * FROM v_integrity_violations ORDER BY invariant_code; SELECT 'P3_RESULT_END:Q0_negative_I3' AS p3_marker;
  ROLLBACK; SET checks=checks+1;
  IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Q0 after I3 rollback'; END IF;

  SET scenario='Q0_I2_union_then_gap'; START TRANSACTION;
  INSERT INTO club(club_code) VALUES('P3_FIXTURE_UNION'); SET xclub=LAST_INSERT_ID();
  INSERT INTO contract(player_id,club_id) SELECT player_id,xclub FROM player WHERE player_code='P060'; SET xcontract=LAST_INSERT_ID();
  INSERT INTO tx_registry(tx_time,author,reason) VALUES(fn_effective_time(),'Part C test','Q0 I2 union fixture rollback'); SET xtx=LAST_INSERT_ID();
  INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_id)
  SELECT xclub,'Fixture',1,'2026-01-01','2026-02-01',tx_time,xtx FROM tx_registry WHERE tx_id=xtx;
  INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_id)
  SELECT xclub,'Fixture',1,'2026-02-01','2026-03-01',tx_time,xtx FROM tx_registry WHERE tx_id=xtx; SET xv2=LAST_INSERT_ID();
  INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id)
  SELECT xcontract,'LOAN',1,'2026-01-15','2026-02-15',tx_time,xtx FROM tx_registry WHERE tx_id=xtx; SET xv=LAST_INSERT_ID();
  IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Q0 I2 adjacent union rejected'; END IF; SET checks=checks+1;
  INSERT INTO tx_registry(tx_time,author,reason) VALUES(fn_effective_time(),'Part C test','Q0 I2 gap fixture rollback'); SET @write_tx_id=LAST_INSERT_ID();
  UPDATE club_version SET tx_to=(SELECT tx_time FROM tx_registry WHERE tx_id=@write_tx_id) WHERE version_id=xv2;
  INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,valid_to,tx_from,tx_id)
  SELECT xclub,'Fixture',1,'2026-02-02','2026-03-01',tx_time,tx_id FROM tx_registry WHERE tx_id=@write_tx_id;
  IF (SELECT COUNT(*) FROM v_integrity_violations WHERE invariant_code='I2' AND source_table='contract_version' AND business_key=xcontract AND version_id=xv)<>1
  OR (SELECT COUNT(*) FROM v_integrity_violations)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Q0 I2 gap diagnosis missing'; END IF;
  SELECT 'P3_RESULT_BEGIN:Q0_negative_I2' AS p3_marker; SELECT * FROM query_params; SELECT * FROM v_integrity_violations; SELECT 'P3_RESULT_END:Q0_negative_I2' AS p3_marker;
  ROLLBACK; SET @write_tx_id=NULL; SET checks=checks+1;
  IF EXISTS(SELECT 1 FROM v_integrity_violations) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Q0 after I2 rollback'; END IF;
  SELECT 'negative executed in isolated clone' AS negative_mode;
 ELSE SELECT 'negative not activated; positive inspection only' AS negative_mode;
 END IF;
 UPDATE query_params SET valid_at=sv,known_at=sk,period_start=ss,period_end=se,subject_id=sid WHERE params_id=1;
 SET @sim_now=NULL,@write_tx_id=NULL;
 DROP TEMPORARY TABLE IF EXISTS p3_expected;
 DROP TEMPORARY TABLE IF EXISTS p3_actual;
 SELECT 'PASS' AS verdict,checks AS assertions,UTC_DATE() AS evaluated_utc_date;
END$$
DELIMITER ;
''']
(ROOT/'05_tests.sql').write_text('\n'.join(out)+'\n')
print(len(CASES),'positive scenarios generated')
