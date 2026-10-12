#!/usr/bin/env python3
"""Local MariaDB orchestration. SQL deliverables themselves do not depend on Python."""
from pathlib import Path
import subprocess,sys,json,hashlib,datetime,uuid,os,csv,re,traceback
ROOT=Path(__file__).resolve().parents[1]
MODE=sys.argv[1]; OPTIONS=sys.argv[2:]
if any(x.startswith(('--password','-p','--force','--database')) for x in OPTIONS):
 raise SystemExit('Use an existing private defaults file, no password/database/force arguments.')
CLIENT=['mariadb',*OPTIONS,'--default-character-set=utf8mb4','--batch','--raw']
DUMP=['mariadb-dump',*OPTIONS,'--default-character-set=utf8mb4','--single-transaction','--routines','--triggers','--hex-blob']
STAMP=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S')+'_'+uuid.uuid4().hex[:6]
LOG=ROOT/'verification/phase2'/f'{MODE}_{STAMP}';LOG.mkdir(parents=True)
manifest={'mode':MODE,'started_utc':STAMP,'status':'running','databases':[],'steps':[]}
FILES=['01_schema.sql','02_data.sql','03_timeline.sql','tests/03_dataset_assertions.sql','tests/04_timeline_assertions.sql','docs/expected_results.json','docs/timeline_plan.json','scripts/phase2_runner.py','scripts/verify_dataset.sh','scripts/populate_main.sh']
def hashes():return {f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in FILES}
def save(): (LOG/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
def invoke(db=None,sql=None,file=None,label=None,expect_failure=None):
 cmd=CLIENT+(['--database='+db] if db else [])
 if sql is not None:cmd+=['--skip-column-names']
 content=('SET NAMES utf8mb4; SET SESSION time_zone=\'+00:00\';\n'+sql) if sql is not None else (ROOT/file).read_text()
 # Confirm target in a separate read immediately before running a file containing DDL.
 if file and invoke(db,sql='SELECT DATABASE();').strip()!=db:raise RuntimeError('Wrong selected database')
 p=subprocess.run(cmd,input=content,text=True,capture_output=True)
 if label:
  (LOG/(label+'.log')).write_text(p.stdout+p.stderr)
  manifest['steps'].append({'step':label,'database':db,'exit_code':p.returncode})
  save()
 if expect_failure:
  if p.returncode==0 or expect_failure not in p.stderr:raise RuntimeError('Expected rejection missing: '+str(expect_failure)+' '+p.stderr)
 elif p.returncode:
  if db:
   try: manifest['last_committed_event']=invoke(db,sql='SELECT MAX(LEFT(reason,3)) FROM tx_registry;').strip()
   except Exception:pass
  raise RuntimeError(f'{label or "SQL"}: exit {p.returncode}: {p.stderr[-2500:]}')
 return p.stdout

def rows(db,sql):return [line.split('\t') for line in invoke(db,sql=sql).splitlines()]
def normalize(db):
 queries={
 'player':'SELECT player_code,full_name,birth_date FROM player ORDER BY player_code',
 'coach':'SELECT coach_code,full_name,birth_date FROM coach ORDER BY coach_code',
 'club':'SELECT club_code FROM club ORDER BY club_code',
 'season':'SELECT season_name,period_start,period_end FROM season ORDER BY season_name',
 'contract':'SELECT p.player_code,c.club_code FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) ORDER BY 1,2',
 'head_coach_role':'SELECT c.club_code FROM head_coach_role a JOIN club c USING(club_id) ORDER BY 1',
 'tx_registry':'SELECT LEFT(reason,3),tx_time,author,reason FROM tx_registry ORDER BY tx_time',
 'tx_event_tag':'SELECT LEFT(r.reason,3),e.event_code FROM tx_event_tag e JOIN tx_registry r USING(tx_id) ORDER BY 1,2',
 'query_params':'SELECT q.params_id,q.valid_at,q.known_at,q.period_start,q.period_end,c.club_code FROM query_params q JOIN club c ON c.club_id=q.subject_id ORDER BY 1',
 'club_version':'SELECT c.club_code,v.club_name,v.budget_eur,v.valid_from,v.valid_to,v.tx_from,v.tx_to,LEFT(r.reason,3) FROM club_version v JOIN club c USING(club_id) JOIN tx_registry r USING(tx_id) ORDER BY 1,6,4,5,2,3',
 'contract_version':'SELECT p.player_code,c.club_code,v.agreement_kind,v.salary_eur,v.valid_from,v.valid_to,v.tx_from,v.tx_to,LEFT(r.reason,3) FROM contract_version v JOIN contract a USING(contract_id) JOIN player p USING(player_id) JOIN club c USING(club_id) JOIN tx_registry r ON r.tx_id=v.tx_id ORDER BY 1,2,7,5,6,3,4',
 'head_coach_role_version':'SELECT c.club_code,h.coach_code,v.valid_from,v.valid_to,v.tx_from,v.tx_to,LEFT(r.reason,3) FROM head_coach_role_version v JOIN head_coach_role a USING(role_id) JOIN club c USING(club_id) JOIN coach h USING(coach_id) JOIN tx_registry r ON r.tx_id=v.tx_id ORDER BY 1,5,3,4,2'}
 return {k:rows(db,v+';') for k,v in queries.items()}
def identity_map(db):return {t:rows(db,f'SELECT {code},{key} FROM {t} ORDER BY {code};') for t,key,code in [('club','club_id','club_code'),('player','player_id','player_code'),('coach','coach_id','coach_code')]}
def schema_fingerprint(db):
 queries={
 'columns':"SELECT TABLE_NAME,COLUMN_NAME,ORDINAL_POSITION,COLUMN_TYPE,IS_NULLABLE,COALESCE(COLUMN_DEFAULT,'<NULL>'),EXTRA,COALESCE(COLLATION_NAME,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,ORDINAL_POSITION",
 'indexes':"SELECT TABLE_NAME,INDEX_NAME,NON_UNIQUE,SEQ_IN_INDEX,COLUMN_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,INDEX_NAME,SEQ_IN_INDEX",
 'fk':"SELECT TABLE_NAME,CONSTRAINT_NAME,REFERENCED_TABLE_NAME,UPDATE_RULE,DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() ORDER BY TABLE_NAME,CONSTRAINT_NAME",
 'checks':"SELECT TABLE_NAME,CONSTRAINT_NAME,CHECK_CLAUSE FROM information_schema.CHECK_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() ORDER BY TABLE_NAME,CONSTRAINT_NAME",
 'triggers':"SELECT TRIGGER_NAME,EVENT_MANIPULATION,EVENT_OBJECT_TABLE,ACTION_TIMING,HEX(ACTION_STATEMENT) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() ORDER BY TRIGGER_NAME",
 'functions':"SELECT ROUTINE_NAME,HEX(ROUTINE_DEFINITION),IS_DETERMINISTIC,SQL_DATA_ACCESS,SECURITY_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_TYPE='FUNCTION' ORDER BY ROUTINE_NAME",
 'view':"SELECT TABLE_NAME,REPLACE(VIEW_DEFINITION,CONCAT('`',DATABASE(),'`.'),'') FROM information_schema.VIEWS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME"}
 return {k:rows(db,v+';') for k,v in queries.items()}
def audit(db,label):
 invoke(db,file='tests/03_dataset_assertions.sql',label=label+'_sql_audit')
 results=[]
 for case in json.loads((ROOT/'docs/expected_results.json').read_text())['cases']:
  actual=rows(db,case['sql']+';'); passed=actual==case['expected']
  results.append({'id':case['id'],'expected':case['expected'],'actual':actual,'pass':passed})
  if not passed:
   (LOG/(label+'_expected_actual.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2))
   raise RuntimeError('Independent expected mismatch '+case['id']+': '+repr(actual))
 (LOG/(label+'_expected_actual.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
 print(label+': '+str(len(results))+' independent expected cases PASS',flush=True)
 return len(results)
def sql_dump(db,path):
 with path.open('w') as f:
  p=subprocess.run(DUMP+[db],stdout=f,stderr=subprocess.PIPE,text=True)
 if p.returncode:raise RuntimeError('mariadb-dump: '+p.stderr)
 if path.stat().st_size<1000:raise RuntimeError('Unexpected empty dump')
 return hashlib.sha256(path.read_bytes()).hexdigest()
def read_complete(db):return invoke(db,sql='SELECT COUNT(*) FROM tx_registry;').strip()=='38'
def write_json(path,data):path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def verify():
 datasets=[]; fingerprints=[]; ids=[]
 for n in (1,2):
  db=f'two_clocks_cabd_verify_p2_{STAMP}_{n}'
  manifest['databases'].append(db);save()
  invoke(sql=f'CREATE DATABASE `{db}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',label=f'create_{n}')
  invoke(db,file='01_schema.sql',label=f'{n}_01_schema')
  fingerprints.append(schema_fingerprint(db))
  if n==2:
   # Actual rolled-back tests naturally advance identifiers; no ALTER AUTO_INCREMENT.
   invoke(db,file='tests/01_schema_smoke.sql',label='2_phase1_smoke')
   invoke(db,file='tests/02_write_examples.sql',label='2_phase1_write_examples')
  invoke(db,file='02_data.sql',label=f'{n}_02_data')
  invoke(db,file='03_timeline.sql',label=f'{n}_03_timeline')
  audit(db,f'{n}_dataset')
  before=normalize(db)
  invoke(db,file='tests/04_timeline_assertions.sql',label=f'{n}_timeline_assertions')
  after=normalize(db)
  if before!=after:raise RuntimeError('Negative tests leaked business changes')
  # Accidental duplicate loads must fail specifically and leave all data identical.
  invoke(db,file='02_data.sql',label=f'{n}_reject_duplicate_02',expect_failure='T01 requires an unpopulated database')
  invoke(db,file='03_timeline.sql',label=f'{n}_reject_duplicate_03',expect_failure='T02 requires exactly prefix')
  if normalize(db)!=before:raise RuntimeError('Duplicate attempt changed dataset')
  datasets.append(before);ids.append(identity_map(db));write_json(LOG/f'{n}_normalized.json',before);write_json(LOG/f'{n}_identity_map.json',ids[-1])
  print(db+': replay, timeline and duplicate guards PASS',flush=True)
 if datasets[0]!=datasets[1]:raise RuntimeError('Two normalized replays differ')
 if ids[0]==ids[1]:raise RuntimeError('Second replay did not exercise different surrogate IDs')
 if fingerprints[0]!=fingerprints[1]:raise RuntimeError('Fresh schema fingerprints differ')
 write_json(LOG/'schema_fingerprint.json',fingerprints[0])
 manifest.update(status='PASS',normalized_equal=True,different_surrogate_ids=True,verified_files=hashes(),normalized_sha256=hashlib.sha256((LOG/'1_normalized.json').read_bytes()).hexdigest())
 save();write_json(ROOT/'verification/phase2/latest_success.json',{'log_dir':str(LOG),'manifest':manifest})
 print('PASS: two independent replays equal by codes and periods',flush=True)
def populate():
 stamp=json.loads((ROOT/'verification/phase2/latest_success.json').read_text()); approved=stamp['manifest']; refdir=Path(stamp['log_dir'])
 if approved['status']!='PASS' or approved['verified_files']!=hashes():raise RuntimeError('Verified files changed or no successful verification; rerun verify first')
 db='two_clocks_cabd';manifest['databases']=[db];save()
 fp=schema_fingerprint(db)
 if fp!=json.loads((refdir/'schema_fingerprint.json').read_text()):raise RuntimeError('Main schema differs from verified schema; no changes made')
 baseline=json.loads((refdir/'1_normalized.json').read_text())
 business=['player','coach','club','season','contract','head_coach_role','tx_registry','tx_event_tag','club_version','contract_version','head_coach_role_version']
 counts={t:int(invoke(db,sql=f'SELECT COUNT(*) FROM {t};').strip()) for t in business}
 write_json(LOG/'main_before_counts.json',counts)
 if any(counts.values()):
  if read_complete(db) and normalize(db)==baseline:
   audit(db,'already_populated');manifest.update(status='PASS',main_action='already populated; no replay and no changes');save();print('ALREADY POPULATED: verified identical; replay refused, no data changed.',flush=True);return
  prefix=invoke(db,sql='SELECT LEFT(reason,3),tx_time FROM tx_registry ORDER BY tx_time;')
  (LOG/'existing_prefix.tsv').write_text(prefix)
  raise RuntimeError('Existing partial or unknown data preserved; reviewed prefix recovery required; no 01/DELETE/DROP/replay executed')
 backup=ROOT/'exports'/f'two_clocks_cabd_before_phase2_{STAMP}.sql'
 manifest['backup']={'path':str(backup),'sha256':sql_dump(db,backup)};manifest['verified_files']=hashes();save()
 invoke(db,file='02_data.sql',label='main_02_data')
 invoke(db,file='03_timeline.sql',label='main_03_timeline')
 audit(db,'main_dataset')
 actual=normalize(db);write_json(LOG/'main_normalized.json',actual)
 if actual!=baseline:raise RuntimeError('Main differs from verified normalized replay')
 out=ROOT/'exports/two_clocks_cabd_phase2.sql'
 manifest['export']={'path':str(out),'sha256':sql_dump(db,out),'restore_tested':False,'replay_tested':True}
 # Export is a native full dump. Its Q0 has schema-qualified view references; replay avoids that.
 text=out.read_text();manifest['export']['contains_use']=bool(re.search(r'^USE ',text,re.M));manifest['export']['qualified_source_view']=f'`{db}`.' in text
 mapping={ref:tx for ref,tx in rows(db,'SELECT LEFT(reason,3),tx_id FROM tx_registry ORDER BY tx_time;')}
 csvfile=ROOT/'docs/timeline.csv'
 if csvfile.exists():
  with csvfile.open(newline='') as f:reader=csv.DictReader(f);fields=reader.fieldnames;data=list(reader)
  for row in data:
   row['tx_id']=mapping[row['event_ref']]
   row['execution_status']='verified_main'
  with csvfile.open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(data)
 write_json(LOG/'event_tx_ids.json',mapping)
 today=rows(db,"SELECT UTC_DATE(),UTC_TIMESTAMP(6),COUNT(DISTINCT contract_id) FROM contract_version WHERE tx_to='9999-12-31 23:59:59.999999' AND valid_from<=UTC_DATE() AND UTC_DATE()<valid_to;")
 write_json(LOG/'today_active.json',today)
 invoke(db,sql="SELECT LEFT(r.reason,3),r.tx_id,r.tx_time,GROUP_CONCAT(e.event_code ORDER BY e.event_code) FROM tx_registry r JOIN tx_event_tag e USING(tx_id) GROUP BY r.tx_id ORDER BY r.tx_time; SELECT * FROM query_params; SELECT COUNT(*) AS q0_count FROM v_integrity_violations;",label='main_final_inspection')
 manifest.update(status='PASS',main_action='populated without schema reset',equal_to_verified_replay=True);save()
 write_json(ROOT/'verification/phase2/main_success.json',{'log_dir':str(LOG),'manifest':manifest})
 print('PASS: main populated, checked, compared and full dump exported',flush=True)
try:
 manifest['initial_files']=hashes();save()
 invoke(sql='SELECT @@hostname,VERSION(),CURRENT_USER(),UTC_TIMESTAMP(6),@@session.time_zone,@@session.sql_mode;',label='server')
 if MODE=='verify':verify()
 elif MODE=='main':populate()
 else:raise ValueError('mode must be verify or main')
except Exception as exc:
 manifest.update(status='FAIL',error=str(exc));save();print('FAIL: '+str(exc),file=sys.stderr,flush=True);sys.exit(1)
finally:
 # Administrative execution produces user-editable artifacts; no ownership outside project.
 owner=os.environ.get('PKEXEC_UID') or os.environ.get('SUDO_UID')
 if os.geteuid()==0 and owner and owner.isdecimal():
  for base in [ROOT/'verification/phase2',ROOT/'exports']:
   for p in [base,*base.rglob('*')]:
    if not p.is_symlink():os.chown(p,int(owner),-1)
