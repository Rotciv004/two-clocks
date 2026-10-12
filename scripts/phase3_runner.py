#!/usr/bin/env python3
"""Part C local runner. No passwords, no reset of main, preserved evidence per run."""
from pathlib import Path
import subprocess,json,hashlib,datetime,uuid,sys,os,re,csv,ast
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
MODE=sys.argv[1];OPTIONS=sys.argv[2:]
if any(x.startswith(('--password','-p','--force','--database')) for x in OPTIONS):raise SystemExit('Use existing private defaults file; no password/force/database options')
CLIENT=['mariadb',*OPTIONS,'--batch','--raw','--default-character-set=utf8mb4']
STAMP=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S')+'_'+uuid.uuid4().hex[:6]
LOG=ROOT/'verification/phase3'/f'{MODE}_{STAMP}';LOG.mkdir(parents=True)
MAN={'mode':MODE,'status':'running','databases':[],'steps':[]}
TABLES=['player','coach','club','season','contract','head_coach_role','club_version','contract_version','head_coach_role_version','tx_registry','tx_event_tag']
EXPECTED=[60,8,6,2,69,6,18,98,15,38,53]
FILES=['01_schema.sql','02_data.sql','03_timeline.sql','04_views.sql','05_tests.sql','docs/query_expected_results.json','scripts/phase3_runner.py']
def dumpjson(name,data): (LOG/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def save():dumpjson('manifest.json',MAN)
def hashes():return {f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in FILES}
def run(db=None,sql=None,file=None,label=None,fail=None):
 content="SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci; SET time_zone='+00:00';\n"+(sql or '')+('\n'+(ROOT/file).read_text() if file else '')
 if file=='tests/01_schema_smoke.sql': content=content.replace('SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;', 'SET NAMES utf8mb4;',1)
 if file and file.startswith('tests/') and file!='tests/01_schema_smoke.sql':
  # Align legacy test session literals with Part C view collation; source artifacts unchanged.
  content=content.replace('SET NAMES utf8mb4;', 'SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;')
 if file and rows(db,'SELECT DATABASE()')[0][0]!=db:raise RuntimeError('Database selection mismatch')
 p=subprocess.run(CLIENT+(['--database='+db] if db else []),input=content,text=True,capture_output=True)
 if label:
  (LOG/(label+'.log')).write_text(p.stdout+p.stderr);MAN['steps'].append({'label':label,'database':db,'exit_code':p.returncode});save()
 if fail:
  if p.returncode==0 or fail not in p.stderr:raise RuntimeError('Expected specific rejection missing: '+fail+' '+p.stderr[-1500:])
 elif p.returncode:raise RuntimeError((label or 'SQL')+': '+p.stderr[-2200:])
 return p.stdout

def rows(db,sql):return [l.split('\t') for l in run(db,sql=sql.rstrip(';')+';').splitlines()[1:]]
# Reuse read-only canonical normalization function without executing phase2 runner.
node=next(n for n in ast.parse((ROOT/'scripts/phase2_runner.py').read_text()).body if isinstance(n,ast.FunctionDef) and n.name=='normalize')
exec(compile(ast.Module(body=[node],type_ignores=[]),'phase2_normalize','exec'))
def business(db):
 data={t:rows(db,f'SELECT * FROM `{t}` ORDER BY 1,2') for t in TABLES}
 return {'counts':{t:len(data[t]) for t in TABLES},'sha256':hashlib.sha256(json.dumps(data,ensure_ascii=False,sort_keys=True).encode()).hexdigest(),'data':data}
def normalized(db):
 d=normalize(db);d.pop('query_params');return d

def structure(db):
 return {k:rows(db,q) for k,q in {
 'tables':"SELECT TABLE_NAME,COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE,COALESCE(COLUMN_DEFAULT,'NULL'),EXTRA FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ("+','.join("'"+t+"'" for t in TABLES+['query_params'])+") ORDER BY TABLE_NAME,ORDINAL_POSITION",
 'triggers':"SELECT TRIGGER_NAME,HEX(ACTION_STATEMENT) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() ORDER BY TRIGGER_NAME",
 'functions':"SELECT ROUTINE_NAME,HEX(ROUTINE_DEFINITION) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_TYPE='FUNCTION' ORDER BY ROUTINE_NAME",
 'indexes':"SELECT TABLE_NAME,INDEX_NAME,SEQ_IN_INDEX,COLUMN_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,INDEX_NAME,SEQ_IN_INDEX"}.items()}

def preflight(db):
 b=business(db)
 if list(b['counts'].values())!=EXPECTED:raise RuntimeError('Unexpected dataset counts '+str(b['counts']))
 if rows(db,'SELECT COUNT(*) FROM query_params')!=[['1']] or rows(db,'SELECT COUNT(*) FROM v_integrity_violations')!=[['0']]:raise RuntimeError('Singleton/Q0 precondition')
 if len(structure(db)['triggers'])!=16:raise RuntimeError('Expected 16 triggers')
 return b

def create(suffix):
 db='two_clocks_cabd_verify_p3_'+STAMP+'_'+suffix
 run(sql=f'CREATE DATABASE `{db}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',label='create_'+suffix)
 MAN['databases'].append(db);save();return db

def captures(text,label):
 root=LOG/label;root.mkdir(exist_ok=True);normalized_results={}
 pattern=r'P3_RESULT_BEGIN:([^\n]+)\n(.*?)p3_marker\nP3_RESULT_END:\1'
 for m in re.finditer(pattern,text,re.S):
  name=m[1].strip();lines=m[2].strip().splitlines();params=dict(zip(lines[0].split('\t'),lines[1].split('\t')))
  result=[x.split('\t') for x in lines[2:]]
  (root/(name+'_params.json')).write_text(json.dumps(params,indent=2)+'\n')
  with (root/(name+'.csv')).open('w',newline='') as f:csv.writer(f).writerows(result)
  if not result:raise RuntimeError('Empty scenario evidence '+name)
  if name.startswith('Q0_negative'):continue
  header=result[0];indices=[i for i,c in enumerate(header) if c not in ['version_id','tx_id','contract_id','club_id','player_id','role_id','subject_id','evaluation_date','elapsed_days','tenure_status']]
  normalized_results[name]=[[r[i] for i in indices] for r in result[1:] if len(r)==len(header)]
 if len(normalized_results)!=52:raise RuntimeError('Expected 52 captured positive scenarios, got '+str(len(normalized_results)))
 dumpjson(label+'_normalized.json',normalized_results);return normalized_results

def test(db,label,negative=False):
 before=business(db);params=rows(db,'SELECT * FROM query_params')
 sql=f"SET @p3_negative={int(negative)},@p3_test_database='{db if negative else ''}';"
 text=run(db,sql=sql,file='05_tests.sql',label=label)
 if business(db)!=before or rows(db,'SELECT * FROM query_params')!=params:raise RuntimeError('Test changed business/parameters')
 MAN.setdefault('test_verdicts',{})[label]=text.split('verdict\tassertions\tevaluated_utc_date\n')[-1].strip();save()
 return captures(text,label+'_results')

def view_export(db,path):
 names=re.findall(r'CREATE OR REPLACE (?:ALGORITHM=TEMPTABLE )?SQL SECURITY INVOKER VIEW (\w+)',(ROOT/'04_views.sql').read_text())
 actual=[r[0] for r in rows(db,"SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA=DATABASE()")]
 order=[n for n in names if n in actual]+sorted(set(actual)-set(names))
 text=f'-- Actual SHOW CREATE VIEW definitions from {db}; not a full backup.\n-- Source qualifiers and DEFINER retained; review for another schema.\nSET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;\n'
 for n in order:
  cp=subprocess.run(['mariadb',*OPTIONS,'--xml','--default-character-set=utf8mb4','--database='+db,'-e',f'SHOW CREATE VIEW `{n}`;'],text=True,capture_output=True)
  if cp.returncode:raise RuntimeError(cp.stderr)
  ddl=ET.fromstring(cp.stdout).find(".//field[@name='Create View']").text
  text+=ddl.replace('CREATE ','CREATE OR REPLACE ',1)+';\n'
 path.write_text(text);return order

def backup(db):
 path=ROOT/'exports'/f'two_clocks_cabd_before_phase3_{STAMP}.sql'
 with path.open('w') as f:
  p=subprocess.run(['mariadb-dump',*OPTIONS,'--single-transaction','--routines','--triggers','--default-character-set=utf8mb4',db],stdout=f,stderr=subprocess.PIPE,text=True)
 if p.returncode:raise RuntimeError(p.stderr)
 return {'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def verify():
 allres=[];alldata=[];identities=[]
 for i in (1,2):
  db=create(str(i));run(db,file='01_schema.sql',label=f'{i}_01')
  if i==2:
   run(db,file='tests/01_schema_smoke.sql',label='2_phase1_smoke')
   run(db,file='04_views.sql',label='2_early04_for_q0_regression')
   run(db,file='tests/02_write_examples.sql',label='2_write_examples')
  run(db,file='02_data.sql',label=f'{i}_02');run(db,file='03_timeline.sql',label=f'{i}_03')
  before=preflight(db);st=structure(db)
  run(db,file='04_views.sql',label=f'{i}_04')
  results=test(db,f'{i}_05',True)
  run(db,file='04_views.sql',label=f'{i}_04_repeat')
  if test(db,f'{i}_05_repeat',True)!=results:raise RuntimeError('04 rerun changed query answers')
  run(db,file='tests/03_dataset_assertions.sql',label=f'{i}_phase2_dataset')
  run(db,file='tests/04_timeline_assertions.sql',label=f'{i}_phase2_timeline')
  run(db,sql="SET @p3_negative=1,@p3_test_database='wrong';",file='05_tests.sql',label=f'{i}_guard_wrong_database',fail='P3_GUARD:')
  # Unexpected read error after parameter changes must restore the caller preset.
  preset=rows(db,'SELECT * FROM query_params')
  run(db,sql='DROP VIEW v_q1_current_contracts;',label=f'{i}_remove_view_error_fixture')
  run(db,sql='SET @p3_negative=0;',file='05_tests.sql',label=f'{i}_restore_params_on_error',fail="doesn't exist")
  if rows(db,'SELECT * FROM query_params')!=preset:raise RuntimeError('Error handler did not restore parameters')
  run(db,file='04_views.sql',label=f'{i}_restore_view_after_error_fixture')
  if business(db)!=before or structure(db)!=st:raise RuntimeError('Views/tests changed data/structure')
  allres.append(results);alldata.append(normalized(db));identities.append(rows(db,'SELECT player_id FROM player ORDER BY player_code'))
  dumpjson(f'{i}_business.json',before);print(db+': 04 rerun, 05 scenarios and regressions PASS',flush=True)
 if allres[0]!=allres[1] or alldata[0]!=alldata[1]:raise RuntimeError('Normalized replay/query mismatch')
 if identities[0]==identities[1]:raise RuntimeError('Different ID exercise missing')
 # Guard on actual main has no fixtures; fail before accessing view scenarios.
 b=business('two_clocks_cabd');pa=rows('two_clocks_cabd','SELECT * FROM query_params')
 run('two_clocks_cabd',sql="SET @p3_negative=1,@p3_test_database=DATABASE();",file='05_tests.sql',label='guard_main',fail='P3_GUARD:')
 if business('two_clocks_cabd')!=b or rows('two_clocks_cabd','SELECT * FROM query_params')!=pa:raise RuntimeError('Main guard altered data')
 MAN.update(normalized_equal=True,different_ids=True,verified_files=hashes())


def install():
 prior=json.loads((ROOT/'verification/phase3/latest_verify.json').read_text())
 if json.loads((Path(prior['log_dir'])/'manifest.json').read_text())['status']!='PASS' or prior['files']!=hashes():raise RuntimeError('Files differ from successful isolated verification')
 db='two_clocks_cabd';MAN['databases']=[db];b=preflight(db);st=structure(db)
 dumpjson('business_before.json',b);dumpjson('structure_before.json',st)
 MAN['backup']=backup(db);view_export(db,LOG/'previous_views.sql');save()
 run(db,file='04_views.sql',label='main_04')
 results=test(db,'main_05',False)
 run(db,sql="UPDATE query_params SET valid_at='2026-03-02',known_at='2026-03-16 12:00:00.000000',period_start='2025-07-01',period_end='2026-07-01',subject_id=(SELECT club_id FROM club WHERE club_code='CL01') WHERE params_id=1;",label='main_preset')
 after=preflight(db);dumpjson('business_after.json',after);dumpjson('params_after.json',rows(db,'SELECT * FROM query_params'))
 if b!=after or st!=structure(db):raise RuntimeError('Main business or base structure changed')
 MAN.update(business_before_sha256=b['sha256'],business_after_sha256=after['sha256'],business_identical=True,views=view_export(db,ROOT/'exports/phase3_views.sql'))
 print('Main: views installed; positive tests PASS; business fingerprint unchanged',flush=True)

def explain():
 db=create('explain')
 for f in ['01_schema.sql','02_data.sql','03_timeline.sql','04_views.sql']:run(db,file=f,label='explain_'+f.split('_')[0])
 b=preflight(db)
 run(db,sql="UPDATE query_params SET subject_id=(SELECT club_id FROM club WHERE club_code='CL03'),valid_at='2026-05-05',known_at='2026-05-11 12:00:00.000000' WHERE params_id=1; SHOW INDEX FROM contract_version; SHOW CREATE TABLE contract_version; SELECT VERSION(); SELECT * FROM query_params;",label='index_metadata')
 query="SELECT * FROM v_q6_bitemporal_point WHERE fact_kind='CONTRACT' ORDER BY subject_code,valid_from,version_id"
 (LOG/'query.sql').write_text("-- CL03; VT 2026-05-05; TT 2026-05-11 12:00 UTC\n"+query+';\n')
 before=run(db,sql=query+';',label='results_with_index')
 run(db,sql='EXPLAIN '+query+';',label='explain_with_index')
 run(db,sql='EXPLAIN FORMAT=JSON '+query+';',label='explain_json_with_index')
 ddl='CREATE INDEX ix_p3_contract_fk_support ON contract_version(contract_id);\nALTER TABLE contract_version DROP INDEX ix_contract_version_asof;'
 (LOG/'index_experiment.sql').write_text(ddl+'\nCREATE INDEX ix_contract_version_asof ON contract_version(contract_id,tx_to,valid_from);\nDROP INDEX ix_p3_contract_fk_support ON contract_version;\n')
 run(db,sql=ddl,label='drop_asof_keep_fk')
 try:
  after=run(db,sql=query+';',label='results_without_index')
  run(db,sql='EXPLAIN '+query+';',label='explain_without_index')
  run(db,sql='EXPLAIN FORMAT=JSON '+query+';',label='explain_json_without_index')
  if before!=after:raise RuntimeError('Q6 results differ without index')
 finally:run(db,sql='CREATE INDEX ix_contract_version_asof ON contract_version(contract_id,tx_to,valid_from); DROP INDEX ix_p3_contract_fk_support ON contract_version;',label='restore_asof')
 if business(db)!=b:raise RuntimeError('EXPLAIN changed business data')
 MAN.update(results_equal=True,index_restored=True,index_name='ix_contract_version_asof',index_columns=['contract_id','tx_to','valid_from'])
 print('EXPLAIN with/without as-of: equal results, index restored in isolated clone',flush=True)
try:
 initial=hashes();MAN['files']=initial;save()
 run(sql='SELECT @@hostname,VERSION(),CURRENT_USER(),UTC_TIMESTAMP(6),@@session.time_zone,@@session.sql_mode;',label='server')
 if MODE=='verify':verify()
 elif MODE=='main':install()
 elif MODE=='explain':explain()
 else:raise RuntimeError('Unknown mode')
 if initial!=hashes():raise RuntimeError('Files changed while running; verification invalid')
 MAN['status']='PASS';save();
 if MODE=='verify': (ROOT/'verification/phase3/latest_verify.json').write_text(json.dumps({'log_dir':str(LOG),'files':hashes()},indent=2))
 (ROOT/'verification/phase3'/('latest_'+MODE+'_success.json')).write_text(json.dumps({'log_dir':str(LOG),'manifest':MAN},indent=2))
 print('PASS '+MODE+' '+str(LOG),flush=True)
except Exception as e:
 MAN.update(status='FAIL',error=str(e));save();print('FAIL '+str(e),file=sys.stderr,flush=True);sys.exit(1)
finally:
 owner=os.environ.get('PKEXEC_UID')
 if os.geteuid()==0 and owner and owner.isdecimal():
  for base in [ROOT/'verification/phase3',ROOT/'exports']:
   for path in [base,*base.rglob('*')]:
    if not path.is_symlink():os.chown(path,int(owner),-1)
