#!/usr/bin/env python3
"""One isolated 01→05 replay of the actual submission. No writes to main."""
import argparse, ast, csv, datetime, hashlib, json, os, pwd, re, subprocess, sys, uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--package-root', type=Path)
parser.add_argument('--evidence-dir', type=Path, required=True)
parser.add_argument('--main-database', help='Optional read-only before/after fingerprint')
parser.add_argument('--defaults-extra-file', type=Path)
args = parser.parse_args()
PKG = (args.package_root or (ROOT if (ROOT/'MANIFEST.sha256').exists() else ROOT/'submission/boar_victor')).resolve()
LOG = args.evidence_dir.resolve()
LOG.mkdir(parents=True, exist_ok=False)
CLIENT = ['mariadb']
if args.defaults_extra_file:
    CLIENT += ['--defaults-extra-file='+str(args.defaults_extra_file.resolve())]
CLIENT += ['--batch', '--raw', '--default-character-set=utf8mb4']
TABLES = ['player','coach','club','season','contract','head_coach_role','club_version','contract_version','head_coach_role_version','tx_registry','tx_event_tag']
EXPECTED = [60,8,6,2,69,6,18,98,15,38,53]
STAMP = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S')+'_'+uuid.uuid4().hex[:8]
DB = 'two_clocks_cabd_verify_p3_submission_'+STAMP
MAN = {'status':'RUNNING','database':DB,'package_root':str(PKG),'cwd':str(Path.cwd()),'steps':[], 'main_read_only':True}

def dump(name,data):
    (LOG/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def save(): dump('manifest.json', MAN)
def run(db=None, sql='', file=None, label=None):
    content = "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci; SET time_zone='+00:00';\n"+sql+'\n'
    if file:
        if db != DB: raise RuntimeError('File execution is restricted to the newly created database')
        if rows(db,'SELECT DATABASE()') != [[DB]]: raise RuntimeError('Wrong selected database')
        source = (PKG/file).read_text()
        if file.startswith('tests/'):
            source = source.replace('SET NAMES utf8mb4;', 'SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;')
        content += source
    proc = subprocess.run(CLIENT+(['--database='+db] if db else []),input=content,text=True,capture_output=True)
    if label:
        (LOG/(label+'.log')).write_text(proc.stdout+proc.stderr)
        MAN['steps'].append({'label':label,'database':db,'exit_code':proc.returncode});save()
    if proc.returncode: raise RuntimeError((label or 'SQL')+': '+proc.stderr[-3000:])
    return proc.stdout
def rows(db,sql):
    return [line.split('\t') for line in run(db,sql=sql.rstrip(';')+';').splitlines()[1:]]
def business(db):
    # EXACT same rows/order/JSON serialization as phase3_runner.business.
    data = {t:rows(db,f'SELECT * FROM `{t}` ORDER BY 1,2') for t in TABLES}
    return {'counts':{t:len(data[t]) for t in TABLES}, 'sha256':hashlib.sha256(json.dumps(data,ensure_ascii=False,sort_keys=True).encode()).hexdigest(), 'data':data}
def normalized(db):
    # The distributed read-only function is copied verbatim from phase2_runner.normalize.
    queries={
      'player':'SELECT player_code,full_name,birth_date FROM player ORDER BY player_code',
      'coach':'SELECT coach_code,full_name,birth_date FROM coach ORDER BY coach_code',
      'club':'SELECT club_code FROM club ORDER BY club_code',
      'season':'SELECT season_name,period_start,period_end FROM season ORDER BY season_name',
      'contract':'SELECT p.player_code,c.club_code FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) ORDER BY 1,2',
      'head_coach_role':'SELECT c.club_code FROM head_coach_role a JOIN club c USING(club_id) ORDER BY 1',
      'tx_registry':'SELECT LEFT(reason,3),tx_time,author,reason FROM tx_registry ORDER BY tx_time',
      'tx_event_tag':'SELECT LEFT(r.reason,3),e.event_code FROM tx_event_tag e JOIN tx_registry r USING(tx_id) ORDER BY 1,2',
      'club_version':'SELECT c.club_code,v.club_name,v.budget_eur,v.valid_from,v.valid_to,v.tx_from,v.tx_to,LEFT(r.reason,3) FROM club_version v JOIN club c USING(club_id) JOIN tx_registry r USING(tx_id) ORDER BY 1,6,4,5,2,3',
      'contract_version':'SELECT p.player_code,c.club_code,v.agreement_kind,v.salary_eur,v.valid_from,v.valid_to,v.tx_from,v.tx_to,LEFT(r.reason,3) FROM contract_version v JOIN contract a USING(contract_id) JOIN player p USING(player_id) JOIN club c USING(club_id) JOIN tx_registry r ON r.tx_id=v.tx_id ORDER BY 1,2,7,5,6,3,4',
      'head_coach_role_version':'SELECT c.club_code,h.coach_code,v.valid_from,v.valid_to,v.tx_from,v.tx_to,LEFT(r.reason,3) FROM head_coach_role_version v JOIN head_coach_role a USING(role_id) JOIN club c USING(club_id) JOIN coach h USING(coach_id) JOIN tx_registry r ON r.tx_id=v.tx_id ORDER BY 1,5,3,4,2'}
    return {k:rows(db,v+';') for k,v in queries.items()}
def structure(db):
    return {kind:rows(db,sql) for kind,sql in {
      'columns':"SELECT TABLE_NAME,COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE,COALESCE(COLUMN_DEFAULT,'NULL'),EXTRA FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,ORDINAL_POSITION",
      'indexes':"SELECT TABLE_NAME,INDEX_NAME,SEQ_IN_INDEX,COLUMN_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,INDEX_NAME,SEQ_IN_INDEX",
      'fk':"SELECT TABLE_NAME,CONSTRAINT_NAME,REFERENCED_TABLE_NAME,UPDATE_RULE,DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() ORDER BY TABLE_NAME,CONSTRAINT_NAME",
      'triggers':"SELECT TRIGGER_NAME,HEX(ACTION_STATEMENT) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() ORDER BY TRIGGER_NAME",
      'functions':"SELECT ROUTINE_NAME,HEX(ROUTINE_DEFINITION) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() ORDER BY ROUTINE_NAME",
      'views':"SELECT TABLE_NAME,HEX(VIEW_DEFINITION),SECURITY_TYPE FROM information_schema.VIEWS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME"}.items()}
def captures(output):
    dest=LOG/'results';dest.mkdir()
    norm={}
    for match in re.finditer(r'P3_RESULT_BEGIN:([^\n]+)\n(.*?)p3_marker\nP3_RESULT_END:\1',output,re.S):
        name=match[1].strip(); lines=match[2].strip().splitlines()
        params=dict(zip(lines[0].split('\t'),lines[1].split('\t')))
        (dest/(name+'_params.json')).write_text(json.dumps(params,indent=2)+'\n')
        result=[line.split('\t') for line in lines[2:]]
        with (dest/(name+'.csv')).open('w',newline='') as handle: csv.writer(handle).writerows(result)
        if name.startswith('Q0_negative'): continue
        header=result[0]
        indices=[i for i,c in enumerate(header) if c not in ['version_id','tx_id','contract_id','club_id','player_id','role_id','subject_id','evaluation_date','elapsed_days','tenure_status']]
        norm[name]=[[r[i] for i in indices] for r in result[1:] if len(r)==len(header)]
    if len(norm)!=52: raise RuntimeError('Expected 52 positive scenario captures')
    dump('query_results_normalized.json',norm)
    return norm

main_before = main_structure = main_params = None
try:
    required=['README.md',*[f'{i:02d}_{name}.sql' for i,name in [(1,'schema'),(2,'data'),(3,'timeline'),(4,'views'),(5,'tests')]],'scripts/verify_submission.py','scripts/verify_submission.sh','tests/03_dataset_assertions.sql','tests/04_timeline_assertions.sql','evidence/business_normalized_reference.json','evidence/query_normalized_reference.json']
    if any(not (PKG/f).is_file() for f in required): raise RuntimeError('Incomplete package')
    MAN['files']={f:hashlib.sha256((PKG/f).read_bytes()).hexdigest() for f in required}
    for name in required[1:6]:
        text=(PKG/name).read_text()
        if re.search(r'^\s*(USE\b|SOURCE\b)|\bDEFINER\s*=',text,re.M|re.I):raise RuntimeError('Non-portable database/account/source dependency in '+name)
    run(sql='SELECT @@hostname,VERSION(),CURRENT_USER(),UTC_TIMESTAMP(6),@@session.time_zone,@@session.sql_mode;',label='server')
    version=rows(None,'SELECT VERSION()')[0][0]
    if not version.startswith('11.8.'):raise RuntimeError('MariaDB 11.8.x required: '+version)
    if args.main_database:
        if not re.fullmatch(r'[A-Za-z0-9_]+',args.main_database):raise RuntimeError('Invalid main name')
        main_before=business(args.main_database);main_structure=structure(args.main_database);main_params=rows(args.main_database,'SELECT * FROM query_params')
        dump('main_business_before.json',main_before);dump('main_structure_before.json',main_structure);dump('main_params_before.json',main_params)
        run(args.main_database,sql='SHOW FULL TABLES; SHOW CREATE FUNCTION fn_effective_time; SHOW INDEX FROM contract_version; SELECT COUNT(*) AS q0 FROM v_integrity_violations; SELECT * FROM query_params;',label='main_read_only_inspection')
        for t in TABLES+['query_params']:
            run(args.main_database,sql=f'SHOW CREATE TABLE `{t}`;',label='main_ddl_'+t)
        for name, *_ in main_structure['views']:
            run(args.main_database,sql=f'SHOW CREATE VIEW `{name}`;',label='main_view_'+name)
    # No IF NOT EXISTS: collision cannot select or recreate a preexisting database.
    run(sql=f'CREATE DATABASE `{DB}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',label='create_new_database')
    for name in ['01_schema.sql','02_data.sql','03_timeline.sql','04_views.sql']:
        run(DB,file=name,label=name.removesuffix('.sql'))
    initial=business(DB);preset=rows(DB,'SELECT * FROM query_params')
    if list(initial['counts'].values())!=EXPECTED:raise RuntimeError('Unexpected dataset counts')
    if rows(DB,'SELECT COUNT(*) FROM v_integrity_violations')!=[['0']]:raise RuntimeError('Q0 nonzero')
    if len(structure(DB)['triggers'])!=16:raise RuntimeError('Guard triggers missing')
    MAN['counts']=initial['counts'];MAN['version']=version
    actual=normalized(DB);reference=json.loads((PKG/'evidence/business_normalized_reference.json').read_text());reference.pop('query_params',None)
    if actual!=reference:raise RuntimeError('Business normalization differs from previous verified replay')
    dump('business_normalized.json',actual)
    output=run(DB,sql=f"SET @p3_negative=1,@p3_test_database='{DB}';",file='05_tests.sql',label='05_tests')
    result=captures(output)
    run(DB,sql='SELECT COUNT(*) AS q0_after_all_rollbacks FROM v_integrity_violations;',label='q0_after_rollbacks')
    if result!=json.loads((PKG/'evidence/query_normalized_reference.json').read_text()):raise RuntimeError('Normalized Q0–Q8 differ from previous verified reference')
    run(DB,file='tests/03_dataset_assertions.sql',label='dataset_assertions')
    run(DB,file='tests/04_timeline_assertions.sql',label='timeline_assertions')
    if business(DB)!=initial or rows(DB,'SELECT * FROM query_params')!=preset:raise RuntimeError('Fixtures/parameters leaked')
    # The failed-attempt section uses historical error logs. This extra final-audit
    # illustration is read-only and explicitly records the missing coalescing.
    naive="SELECT DISTINCT c.club_code,h.coach_code,v.valid_from,v.valid_to FROM head_coach_role_version v JOIN head_coach_role a USING(role_id) JOIN club c USING(club_id) JOIN coach h USING(coach_id) WHERE c.club_code='CL04' AND v.tx_to='9999-12-31 23:59:59.999999' ORDER BY v.valid_from;"
    (LOG/'q2_without_coalescing.sql').write_text(naive+'\n')
    wrong=rows(DB,naive)
    expected=[['CL04','H05','2025-07-01','9999-12-31']]
    dump('q2_without_coalescing.json',{'purpose':'final audit demonstration, not development history','actual_naive':wrong,'expected_independent':expected,'naive_mismatch_demonstrated':wrong!=expected})
    if len(wrong)!=2 or wrong==expected:raise RuntimeError('Coalescing illustration not demonstrated')
    MAN.update(status='PASS',positive_scenarios=52,q0_extra_checks=4,normalized_business_equal=True,normalized_queries_equal=True,fixtures_rolled_back=True,params_restored=True)
    print('PASS: one packaged 01→05 replay; 52 positive + 4 Q0 checks; regressions; normalized results equal.',flush=True)
except Exception as exc:
    MAN.update(status='FAIL',error=str(exc));print('FAIL: '+str(exc),file=sys.stderr,flush=True)
finally:
    if main_before is not None:
        try:
            after=business(args.main_database);st=structure(args.main_database);pa=rows(args.main_database,'SELECT * FROM query_params')
            dump('main_business_after.json',after);dump('main_structure_after.json',st);dump('main_params_after.json',pa)
            unchanged=main_before==after and main_structure==st and main_params==pa
            MAN.update(main_business_before_sha256=main_before['sha256'],main_business_after_sha256=after['sha256'],main_unchanged=unchanged)
            if not unchanged:MAN.update(status='FAIL',error='Main changed during verification')
        except Exception as exc:MAN.update(status='FAIL',error='Main final audit: '+str(exc))
    save()
    owner=os.environ.get('PKEXEC_UID')
    if os.geteuid()==0 and owner and owner.isdecimal():
        uid=int(owner);gid=pwd.getpwuid(uid).pw_gid
        for path in [LOG,*LOG.rglob('*')]:
            if not path.is_symlink():os.chown(path,uid,gid)
sys.exit(0 if MAN['status']=='PASS' else 1)
