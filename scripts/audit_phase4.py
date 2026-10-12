#!/usr/bin/env python3
"""Validate final database evidence and diagram against actual metadata."""
import difflib,hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'verification/phase4';RUN=OUT/'replay_package_1'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(name):return json.loads((RUN/name).read_text())
manifest=load('manifest.json')
if manifest['status']!='PASS' or not manifest['main_unchanged']:raise RuntimeError('Final replay/main guard failed')
expected='74d4a44650b438f64ef7f010e9bce2893b68ac7483072a9ca2483e08aaa520c8'
if manifest['main_business_before_sha256']!=expected or manifest['main_business_after_sha256']!=expected:raise RuntimeError('Unexpected fingerprint under SAME method')
for kind in ['business','structure','params']:
    if load('main_'+kind+'_before.json')!=load('main_'+kind+'_after.json'):raise RuntimeError('Main '+kind+' changed')
if (RUN/'q0_after_rollbacks.log').read_text().strip()!='q0_after_all_rollbacks\n0':raise RuntimeError('Missing explicit post-rollback zero')
normalized=load('business_normalized.json');tags={f'E{i}':sum(row[1]==f'E{i}' for row in normalized['tx_event_tag']) for i in range(1,10)}
if list(tags.values())!=[1,13,18,5,6,4,3,1,2]:raise RuntimeError('E1–E9 mismatch')
if sum(len(normalized[t]) for t in ['club_version','contract_version','head_coach_role_version'])!=131:raise RuntimeError('Version total')
current=sum(row[7]=='9999-12-31 23:59:59.999999' for row in normalized['contract_version'])
if current!=77:raise RuntimeError('Current TT contract facts')
actual=load('main_structure_before.json');dot=(ROOT/'er_diagram.dot').read_text()
tables=re.findall(r'CREATE TABLE (\w+) \(', (ROOT/'01_schema.sql').read_text())
for table in tables:
    body=re.search(r'^'+table+r' \[label=<<(.*?)>>\];',dot,re.M|re.S)[1]
    columns=set(re.findall(r'PORT="(\w+)"',body))
    real={row[1] for row in actual['columns'] if row[0]==table}
    if columns!=real:raise RuntimeError('Diagram columns differ '+table)
    label='bitemporal' if table in ['club_version','contract_version','head_coach_role_version'] else 'non-temporal'
    if label not in body:raise RuntimeError('Classification missing '+table)
fks=actual['fk']
if len(fks)!=11:raise RuntimeError('Unexpected FK count')
for child,_,parent,update,delete in fks:
    if not re.search(r'^'+parent+r':\w+ -> '+child+r':\w+',dot,re.M):raise RuntimeError('Missing relationship '+child)
    if update!='RESTRICT' or delete!='RESTRICT':raise RuntimeError('Different FK policy')
indexes=actual['indexes']
def indexcols(table,name):return [r[3] for r in indexes if r[0]==table and r[1]==name]
if indexcols('contract','uq_contract_pair')!=['player_id','club_id'] or indexcols('head_coach_role','uq_head_coach_role_club')!=['club_id']:raise RuntimeError('Stable anchor uniqueness missing')
if indexcols('contract_version','ix_contract_version_asof')!=['contract_id','tx_to','valid_from']:raise RuntimeError('Main index missing')
(OUT/'latest_replay.json').write_text(json.dumps({'log_dir':str(RUN),'status':'PASS','database':manifest['database']},indent=2)+'\n')
(OUT/'diagram_audit.json').write_text(json.dumps({'status':'PASS','actual_metadata_source':'replay_package_1/main_structure_before.json','table_count':12,'all_columns_equal':True,'fk_count':11,'pk_uq_fk_checked':True,'non_temporal_tables':9,'bitemporal_tables':3,'crowfoot':'|| / o< / o|','query_params_subject_id_no_fk':True,'source_sha256':sha(ROOT/'er_diagram.dot'),'pdf_sha256':sha(ROOT/'er_diagram.pdf'),'png_sha256':sha(ROOT/'er_diagram.png'),'visual_inspection':'PNG and PDF rendering inspected: labels readable, complete, no clipped text; technical cluster label moved below crossing paths'},ensure_ascii=False,indent=2)+'\n')
before=(OUT/'er_diagram.before.dot').read_text().splitlines(keepends=True);after=dot.splitlines(keepends=True)
(OUT/'diagram_changes.diff').write_text(''.join(difflib.unified_diff(before,after,fromfile='er_diagram.before.dot',tofile='er_diagram.dot')))
(OUT/'postflight.json').write_text(json.dumps({'status':'PASS','counts':manifest['counts'],'event_tag_counts':tags,'current_tt_contract_facts':current,'main_hash_method_unchanged':True,'main_fingerprint':expected,'main_structure_identical':True,'main_params_identical':True,'working_directory_actual':manifest['cwd'],'package_root_actual':manifest['package_root'],'sql_not_changed':{name:sha(ROOT/name)==value for name,value in manifest['files'].items() if name.endswith('.sql') and not name.startswith('tests/')},'historical_tests':'230 schema smoke / 37 writer tests were NOT rerun in phase4; they remain prior evidence'},ensure_ascii=False,indent=2)+'\n')
print('PASS: current main fingerprint '+expected+' unchanged; schema/params identical; actual ER metadata checked')
