#!/usr/bin/env python3
"""Read-only source audit and explicit submission selection; no database access."""
import csv, hashlib, json, re, shutil, sys, zipfile, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/phase4'
PKG=ROOT/'submission/boar_victor'
MAIN=ROOT/'verification/phase3/main_20261009_073229_1a92c6'
VERIFY=ROOT/'verification/phase3/verify_20261009_072839_ef3341'
EXPLAIN=ROOT/'verification/phase3/explain_20261009_073306_d03aa8'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def putjson(path,data):path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def copy(src,dest):dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest)

def audit():
    OUT.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((MAIN/'manifest.json').read_text())
    files={name:{'sha256':sha(ROOT/name),'matches_phase3_success':sha(ROOT/name)==expected}
           for name,expected in manifest['files'].items()}
    if not all(x['matches_phase3_success'] for x in files.values()):raise RuntimeError('SQL/expected/runner changed since verified Part C')
    refs=json.loads((ROOT/'docs/references/sources.json').read_text())
    pdfs={Path(item['copy']).name:{'sha256':sha(ROOT/'docs/references'/Path(item['copy']).name),'matches_original':sha(ROOT/'docs/references'/Path(item['copy']).name)==item['sha256']} for item in refs}
    if not all(x['matches_original'] for x in pdfs.values()):raise RuntimeError('Reference PDFs changed')
    schema=(ROOT/'01_schema.sql').read_text();dot=(ROOT/'er_diagram.dot').read_text()
    tables=re.findall(r'CREATE TABLE (\w+) \(',schema)
    fks=re.findall(r'CREATE TABLE (\w+) \((.*?)\) ENGINE=',schema,re.S)
    relations=[]
    for child,ddl in fks:
        for col,parent,pcol in re.findall(r'FOREIGN KEY \((\w+)\) REFERENCES (\w+) \((\w+)\)',ddl):
            if f'{parent}:{pcol} -> {child}:{col}' not in dot:raise RuntimeError('Diagram missing FK '+child+'.'+col)
            relations.append({'parent':parent,'child':child,'column':col,'cardinality':'1 → 0..1' if child=='head_coach_role' else '1 → 0..N'})
    for table in tables:
        if not re.search(r'^'+table+r' \[label=',dot,re.M):raise RuntimeError('Diagram missing '+table)
    checks=['UQ(player_id, club_id)','UQ(club_id)','subject_id fără FK','arrowtail=teetee','arrowhead=crowodot','arrowhead=teeodot']
    if not all(x in dot for x in checks):raise RuntimeError('Diagram constraints/cardinalities missing')
    deps={name:re.findall(r'^\s*(?:USE|SOURCE)\s+.*|DEFINER\s*=.*|/home/[^\s\x27\x22]+', (ROOT/name).read_text(),re.M|re.I) for name in ['01_schema.sql','02_data.sql','03_timeline.sql','04_views.sql','05_tests.sql']}
    if any(deps.values()):raise RuntimeError('Portable SQL dependency audit failed')
    failures={
      'q3_group_function':ROOT/'verification/phase3/verify_20261009_072417_120630/1_04.log',
      'collation':ROOT/'verification/phase3/verify_20261009_072447_b308ea/1_phase2_dataset.log',
      'smoke_after_views':ROOT/'verification/phase3/verify_20261009_072533_d103ef/2_phase1_smoke.log'}
    for label,path in failures.items():copy(path,OUT/'historical_failures'/path.parent.name/(label+'.log'))
    timeline=(ROOT/'03_timeline.sql').read_text()
    full_examples='-- Exemple complete, copiate VERBATIM din cronologia verificată.\n-- Nu rula pe two_clocks_cabd. Se selectează UN SINGUR bloc pe clona\n-- de replay aflată exact după T17 (T18), T18 (T19), respectiv T24 (T25).\n-- Precondiții/lock-uri/handler ROLLBACK, snapshot I4/Q0 și COMMIT incluse.\n-- Headerul comun de mai jos pregătește tabelele temporare în fiecare sesiune.\n\n'+timeline.split('-- BEGIN EVENT T02:')[0]
    review=[]
    for event in re.findall(r'-- BEGIN EVENT (T\d+):',timeline):
        block=re.search(r'-- BEGIN EVENT '+event+r':.*?-- END EVENT '+event,timeline,re.S)[0]
        match=re.search(r"^SET @sim_now='.*?(?=IF NOT COALESCE\(\(NOT EXISTS\(SELECT 1 FROM p2_before_club_version)",block,re.S|re.M)
        review.append(match[0] if match else block)
        if event in ['T18','T19','T25']:full_examples+='\n-- SELECT ONLY THIS EVENT: '+event+'\n'+block+'\n'
    (ROOT/'docs/report_write_examples.sql').write_text(full_examples)
    (OUT/'timeline_business_actions.sql').write_text('\n\n'.join(review))
    putjson(OUT/'source_audit.json',{'files':files,'reference_pdfs':pdfs,'tables':tables,'fk_relations':relations,'runtime_dependencies':deps,'diagram_static_match':True,'timeline_events_reviewed':len(review),'main_fingerprint_method':'phase3_runner.business: SELECT * ORDER BY 1,2; json.dumps(data, ensure_ascii=False, sort_keys=True); SHA256; query_params excluded'})
    print('PASS source audit: unchanged SQL, reference PDFs, 12 diagram tables/11 FK edges, portable 01–05')

def prepare():
    PKG.mkdir(parents=True,exist_ok=True)
    files=['01_schema.sql','02_data.sql','03_timeline.sql','04_views.sql','05_tests.sql',
      'scripts/verify_submission.sh','scripts/verify_submission.py',
      'tests/01_schema_smoke.sql','tests/02_write_examples.sql','tests/03_dataset_assertions.sql','tests/04_timeline_assertions.sql',
      'docs/schema_design.md','docs/write_protocol.md','docs/data_plan.md','docs/query_catalog.md',
      'docs/timeline.csv','docs/timeline_plan.json','docs/expected_results.json','docs/query_expected_results.json',
      'docs/report_write_examples.sql']
    for f in files:copy(ROOT/f,PKG/f)
    story=(ROOT/'README.md').read_text().split('### Story log — 38 de evenimente proiectate')[1].split('## Livrabile Part C')[0]
    (PKG/'README.md').write_text((ROOT/'docs/submission_README.md').read_text().replace('{{STORY_LOG}}',story.strip()))
    copy(ROOT/'verification/phase2/verify_20261008_215031_8588ef/1_normalized.json',PKG/'evidence/business_normalized_reference.json')
    copy(MAIN/'main_05_results_normalized.json',PKG/'evidence/query_normalized_reference.json')
    for f in ['query.sql','index_metadata.log','explain_with_index.log','explain_without_index.log','explain_json_with_index.log','explain_json_without_index.log','results_with_index.log','results_without_index.log','restore_asof.log','index_experiment.sql','manifest.json']:
        copy(EXPLAIN/f,PKG/'evidence/explain'/f)
    for path in (OUT/'historical_failures').rglob('*.log'):copy(path,PKG/'evidence/historical_failures'/path.relative_to(OUT/'historical_failures'))
    for name in ['manifest.json','server.log']:copy(MAIN/name,PKG/'evidence/phase3_main'/name)
    copy(VERIFY/'manifest.json',PKG/'evidence/phase3_replay_manifest.json')
    copy(ROOT/'verification/phase3/monthly_oracle_check.json',PKG/'evidence/monthly_oracle_check.json')
    print('Prepared exact runnable submission selection: '+str(PKG))

def finalize():
    for f in ['report.pdf','er_diagram.pdf','er_diagram.png','er_diagram.dot','docs/report.md','docs/report_evidence_map.md','docs/requirements_matrix.md','docs/report_write_examples.sql','scripts/build_report.py','scripts/check_report.py','docs/report_requirements.txt']:
        copy(ROOT/f,PKG/f)
    # Font files are required by the offline report build, selected explicitly.
    for name in ['NotoSans-Regular.ttf','NotoSans-Bold.ttf','NotoSansMono-Regular.ttf','NotoSansMath-Regular.ttf']:
        copy(Path('/usr/share/fonts/google-noto')/name,PKG/'docs/fonts'/name)
    copy(Path('/usr/share/licenses/google-noto-fonts-common/LICENSE'),PKG/'docs/fonts/OFL.txt')
    latest=json.loads((OUT/'latest_replay.json').read_text()); replay=Path(latest['log_dir'])
    if json.loads((replay/'manifest.json').read_text())['status']!='PASS':raise RuntimeError('Replay not PASS')
    for path in replay.rglob('*'):
        if path.is_file() and not path.name.startswith('main_'):copy(path,PKG/'evidence/replay'/path.relative_to(replay))
    for f in ['source_audit.json','report_layout.json','pdf_checks.json','diagram_audit.json','postflight.json','visual_review.md']:
        copy(OUT/f,PKG/'evidence'/f)
    copy(replay/'main_structure_before.json',PKG/'evidence/schema_metadata.json')
    for name in ['summary.md','phase2_summary.md','phase3_summary.md']:
        copy(ROOT/'verification'/name,PKG/'evidence/historical_summaries'/name)
    story=(ROOT/'README.md').read_text().split('### Story log — 38 de evenimente proiectate')[1].split('## Livrabile Part C')[0]
    (PKG/'README.md').write_text((ROOT/'docs/submission_README.md').read_text().replace('{{STORY_LOG}}',story.strip()))
    # Distributed runtime SQL and verification code must be exactly what ran.
    runmanifest=json.loads((replay/'manifest.json').read_text())
    for name,digest in runmanifest['files'].items():
        if name=='README.md':continue
        if sha(PKG/name)!=digest:raise RuntimeError('Tested runtime file changed: '+name)
    # This adaptation only makes documentary links portable; SQL is unchanged.
    for f in ['schema_design.md','write_protocol.md','data_plan.md','query_catalog.md']:
        p=PKG/'docs'/f;text=p.read_text()
        text=text.replace('`verification/summary.md`','`evidence/phase3_replay_manifest.json`')
        text+='\n\nStarea finală de predare este în README și requirements_matrix.md. Formulările istorice „planificat” descriu etapele anterioare. PDF-urile cursului sunt consultate în proiectul autorului; pachetul nu redistribuie materialul de curs.\n'
        p.write_text(text)
    paths=sorted(p for p in PKG.rglob('*') if p.is_file() and p.name!='MANIFEST.sha256')
    (PKG/'MANIFEST.sha256').write_text(''.join(sha(p)+'  '+p.relative_to(PKG).as_posix()+'\n' for p in paths))
    zip_path=ROOT/'submission/boar_victor_assignment1.zip'
    with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as archive:
        for path in [*paths,PKG/'MANIFEST.sha256']:archive.write(path,'boar_victor/'+path.relative_to(PKG).as_posix())
    extraction=Path(tempfile.mkdtemp(prefix='cabd-submission-extracted-'))
    with zipfile.ZipFile(zip_path) as archive:
        if archive.testzip() is not None:raise RuntimeError('ZIP CRC failure')
        archive.extractall(extraction)
    extracted=extraction/'boar_victor'
    for line in (extracted/'MANIFEST.sha256').read_text().splitlines():
        digest,name=line.split('  ',1)
        if sha(extracted/name)!=digest:raise RuntimeError('Extracted manifest mismatch '+name)
    actual={p.relative_to(extracted).as_posix() for p in extracted.rglob('*') if p.is_file()}
    expected={p.relative_to(PKG).as_posix() for p in paths}|{'MANIFEST.sha256'}
    if actual!=expected:raise RuntimeError('Archive file selection differs')
    for required in ['01_schema.sql','02_data.sql','03_timeline.sql','04_views.sql','05_tests.sql','scripts/verify_submission.py','tests/03_dataset_assertions.sql','tests/04_timeline_assertions.sql','evidence/business_normalized_reference.json','evidence/query_normalized_reference.json','report.pdf','er_diagram.pdf']:
        if not (extracted/required).is_file():raise RuntimeError('Archive dependency missing '+required)
    if sha(extracted/'report.pdf')!=sha(ROOT/'report.pdf'):raise RuntimeError('PDF differs from visually checked final')
    putjson(OUT/'archive_validation.json',{'zip':str(zip_path),'sha256':sha(zip_path),'extracted_to':str(extracted),'file_count':len(actual),'crc_pass':True,'manifest_pass':True,'all_files_identical':True,'runtime_identical_to_tested_package':True,'runtime_status':'PASS','report_sha256':sha(ROOT/'report.pdf'),'er_pdf_sha256':sha(ROOT/'er_diagram.pdf')})
    (ROOT/'submission/SHA256SUMS').write_text(sha(zip_path)+'  boar_victor_assignment1.zip\n'+sha(PKG/'MANIFEST.sha256')+'  boar_victor/MANIFEST.sha256\n'+sha(ROOT/'report.pdf')+'  boar_victor/report.pdf\n'+sha(ROOT/'er_diagram.pdf')+'  boar_victor/er_diagram.pdf\n')
    print('PASS ZIP extraction, manifest, dependencies and final PDF equality: '+str(zip_path))

{'audit':audit,'prepare':prepare,'finalize':finalize}[sys.argv[1]]()
