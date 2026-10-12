#!/usr/bin/env python3
"""Offline, deterministic five-page A4 report; all result tables derive from CSV."""
import argparse, csv, hashlib, html, json, re, textwrap
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle, Preformatted

ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('--evidence-root',type=Path,required=True)
ap.add_argument('--output',type=Path,default=ROOT/'report.pdf')
ap.add_argument('--audit-dir',type=Path,help='Write layout evidence outside an extracted package')
args=ap.parse_args(); E=args.evidence_root.resolve(); R=E/'results'
OUT=args.output.resolve();OUT.parent.mkdir(parents=True,exist_ok=True)
FONTS=ROOT/'docs/fonts'
if not FONTS.exists():FONTS=Path('/usr/share/fonts/google-noto')
for alias,name in [('Body','NotoSans-Regular.ttf'),('Bold','NotoSans-Bold.ttf'),('Mono','NotoSansMono-Regular.ttf'),('Math','NotoSansMath-Regular.ttf')]:
    pdfmetrics.registerFont(TTFont(alias,str(FONTS/name)))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Body',boldItalic='Bold')
styles={
 'body':ParagraphStyle('body',fontName='Body',fontSize=10.1,leading=12.1,spaceAfter=4),
 'h1':ParagraphStyle('h1',fontName='Bold',fontSize=15,leading=18,spaceAfter=7),
 'h2':ParagraphStyle('h2',fontName='Bold',fontSize=12,leading=14,spaceAfter=5,spaceBefore=4),
 'h3':ParagraphStyle('h3',fontName='Bold',fontSize=10.5,leading=12.5,spaceAfter=3,spaceBefore=3),
 'small':ParagraphStyle('small',fontName='Body',fontSize=8,leading=9.2,spaceAfter=2),
 'cell':ParagraphStyle('cell',fontName='Body',fontSize=8,leading=9.2),
 'code':ParagraphStyle('code',fontName='Mono',fontSize=8.1,leading=9.15,spaceAfter=3)}
WIDTH=A4[0]-66; LEFT=33;TOP=A4[1]-30;BOTTOM=30
checks={'sources':{},'tables':{},'font_sizes':{'body':10.1,'table':8,'code':8.1},'pages':[]}
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def records(name):
    path=R/(name+'.csv');checks['sources'][str(path.relative_to(E))]=sha(path)
    with path.open(newline='') as handle:return list(csv.DictReader(handle))
def params(name):return json.loads((R/(name+'_params.json')).read_text())
def par(value,style='body'):
    escaped=html.escape(str(value));escaped=re.sub(r'`([^`]+)`',r'<font name="Mono">\1</font>',escaped)
    for symbol in ['→','∞']:escaped=escaped.replace(symbol,'<font name="Math">'+symbol+'</font>')
    return Paragraph(escaped,styles[style])
def table(header,body,widths):
    rows=[[par(cell,'cell') for cell in row] for row in [header,*body]]
    t=Table(rows,colWidths=widths,hAlign='LEFT')
    t.setStyle(TableStyle([('FONTNAME',(0,0),(-1,-1),'Body'),('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e7edf3')),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),2),('RIGHTPADDING',(0,0),(-1,-1),2),('TOPPADDING',(0,0),(-1,-1),0.7),('BOTTOMPADDING',(0,0),(-1,-1),0.7),('LINEBELOW',(0,0),(-1,0),0.45,colors.HexColor('#74849a')),('LINEBELOW',(0,1),(-1,-1),0.15,colors.HexColor('#d9dfe6'))]))
    return t
def short_number(value):
    return value[:-3] if str(value).endswith('.00') else str(value)
def compact_values(row,column):
    raw=row[column]
    values=[] if raw=='NULL' else json.loads(raw)
    result=[]
    for fact in values:
        value=short_number(fact['value'])
        if row['fact_family']=='CONTRACT':value=fact['business_key'].split('/')[1]+':'+value
        if value not in result:result.append(value)
    return '|'.join(result) or '—'

q1=records('Q1_today_P006');q2=records('Q2_today_CL04');q3=records('Q3_all_events');q5=records('Q5_final');q7=records('Q7_season1');q8=records('Q8_all_gaps')
if len(q1)!=2 or len(q2)!=1 or len(q3)!=33 or len(q5)!=77 or len(q7)!=72 or len(q8)!=4:raise RuntimeError('Unexpected report dataset cardinalities')
if len({r['event_ref'] for r in q3})!=31:raise RuntimeError('Q3 event count differs')
if {(r['club_code'],r['agreement_kind'],r['salary_eur']) for r in q1}!={('CL01','PERMANENT','1060.00'),('CL02','LOAN','650.00')}:raise RuntimeError('Q1 dates/values changed; revise report narrative')
if params('Q5_final')['known_at']!='2026-09-21 12:00:00.000000':raise RuntimeError('Q5 wrong time')
checks['tables']={'Q1':len(q1),'Q2':len(q2),'Q3_components':len(q3),'Q3_events':31,'Q5':len(q5),'Q7_values':len(q7),'Q8':len(q8)}
TABLES={}
negative=[]
for name,code in [('Q0_negative_I1','I1'),('Q0_negative_I3','I3'),('Q0_negative_I2','I2')]:
    row=next(r for r in records(name) if r['invariant_code']==code)
    negative.append([code,row['source_table'],row['business_key'],row['version_id']+'/'+row['conflicting_version_id'],row['details']])
TABLES['q0']=table(['Inv.','Tabel','Cheie','v / conflict','Diagnostic real'],negative,[28,134,28,52,WIDTH-242])
TABLES['q1']=table(['Jucător','Club','Tip','Salariu EUR'],[[r[c] for c in ['player_code','club_code','agreement_kind','salary_eur']] for r in q1],[80,80,150,WIDTH-310])
rows3=[[r['event_ref'],{'CONTRACT':'C','CLUB':'B','HEAD_COACH':'H'}[r['fact_family']]+'/'+r['subject_code'],r['event_codes'],r['effective_date'][2:],r['delay_days'],compact_values(r,'old_values'),compact_values(r,'new_values')] for r in q3]
TABLES['q3']=table(['Ref','Familie/subiect','E','VT efectiv','Δ zile','Valori vechi','Valori noi'],rows3,[26,65,42,47,29,137,WIDTH-346])
blocks=[]
for start in range(0,77,26):
    chunk=q5[start:start+26]
    data=[[r['player_code'],r['club_code'],'P' if r['agreement_kind']=='PERMANENT' else 'L',short_number(r['salary_eur']),r['valid_from'][2:]+'/'+('∞' if r['valid_to']=='9999-12-31' else r['valid_to'][2:])] for r in chunk]
    blocks.append(table(['Juc.','Club','K','EUR','VT [de la/până)'],data,[25,23,10,30,83]))
TABLES['q5']=Table([[blocks[0],'',blocks[1],'',blocks[2]]],colWidths=[171,8,171,8,171],hAlign='LEFT')
TABLES['q5'].setStyle(TableStyle([('FONTNAME',(0,0),(-1,-1),'Body'),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),0),('RIGHTPADDING',(0,0),(-1,-1),0),('TOPPADDING',(0,0),(-1,-1),0),('BOTTOMPADDING',(0,0),(-1,-1),0)]))
points=[]
for n in range(1,4):
    name='Q6_perspective_'+str(n);row=next(r for r in records(name) if r['fact_kind']=='HEAD_COACH')
    points.append([params(name)['known_at'],row['subject_code'],row['subject_name']])
if [r[1] for r in points]!=['H01','H02','H01']:raise RuntimeError('Q6 A→B→A missing')
for event,codes in [('T18',['H01','H02','H02']),('T19',['H02','H01','H01'])]:
    found=[next(r for r in records('Q6_'+event+'_'+s) if r['fact_kind']=='HEAD_COACH')['subject_code'] for s in ['before','exact','after']]
    if found!=codes:raise RuntimeError('Q6 microsecond boundary mismatch')
for scenario,player,club,flags in [('Q4_season1','P018','CL02',('1','1')),('Q4_season1','P001','CL06',('1','0')),('Q4_exact_loan','P006','CL02',('1','1')),('Q4_touch_loan','P006','CL02',('0','0'))]:
    row=next(r for r in records(scenario) if r['player_code']==player and r['club_code']==club and (scenario=='Q4_season1' or r['valid_from']=='2026-06-01'))
    if (row['at_some_point'],row['throughout'])!=flags:raise RuntimeError('Q4 narrative mismatch')
tag_counts={tag:len({r['event_ref'] for r in q3 if tag in r['event_codes'].split(',')}) for tag in ['E2','E3','E4']}
if tag_counts!={'E2':13,'E3':18,'E4':5}:raise RuntimeError('Q3 tag counts changed')
correction=next(r for r in q3 if r['event_ref']=='T19')
if [(x['value'],x['valid_to'] if x['value']=='H01' else x['valid_from']) for x in json.loads(correction['old_values'])]!=[('H01','2026-03-01'),('H02','2026-03-01')]:raise RuntimeError('T19 old boundaries changed')
if [(x['value'],x['valid_to'] if x['value']=='H01' else x['valid_from']) for x in json.loads(correction['new_values'])]!=[('H01','2026-03-03'),('H02','2026-03-03')]:raise RuntimeError('T19 new boundaries changed')
TABLES['q6']=table(['known_at UTC','Cod','Antrenor'],points,[230,50,WIDTH-280])
TABLES['q8']=table(['Pereche','gap_from','gap_to','Zile'],[[r['player_code']+'–'+r['club_code'],r['gap_from'],r['gap_to'],r['gap_days']] for r in q8],[130,150,150,WIDTH-430])
clubs=sorted({r['club_code'] for r in q7});months=sorted({r['month_start'] for r in q7})
matrix={(r['month_start'],r['club_code']):r['relationship_count'] for r in q7}
if len(matrix)!=72 or matrix[('2025-07-01','CL06')]!='0':raise RuntimeError('Monthly pivot incomplete')
TABLES['q7']=table(['Luna',*clubs],[[m[:7],*[matrix[m,c] for c in clubs]] for m in months],[75,*[(WIDTH-75)/6]*6])
explain=ROOT/'evidence/explain'
if not explain.exists():explain=ROOT/'verification/phase3/explain_20261009_073306_d03aa8'
plans=[];full_plans=[]
for label,file in [('Cu as-of','explain_with_index.log'),('Fără as-of','explain_without_index.log')]:
    path=explain/file
    with path.open(newline='') as handle:plan=list(csv.DictReader(handle,delimiter='\t'))
    if len(plan)!=7:raise RuntimeError('Unexpected full EXPLAIN plan size')
    full_plans.append(plan)
    row=next(r for r in plan if r['table']=='v')
    plans.append([label,row['type'],row['key'],row['rows'],row['Extra']]);checks['sources']['explain/'+file]=sha(path)
if plans[0][1:4]!=['ALL','NULL','98'] or plans[1][1:4]!=['ref','ix_p3_contract_fk_support','1']:raise RuntimeError('EXPLAIN changed')
if (explain/'results_with_index.log').read_bytes()!=(explain/'results_without_index.log').read_bytes():raise RuntimeError('EXPLAIN query results differ')
explain_manifest=json.loads((explain/'manifest.json').read_text())
if not explain_manifest['index_restored'] or not explain_manifest['results_equal']:raise RuntimeError('Index restoration/equivalence evidence missing')
key_aliases={'NULL':'NULL','PRIMARY':'PK','ix_contract_club':'CL','ix_p3_contract_fk_support':'FK'}
extra_aliases={'':'—','Using where':'W','Using where; Using filesort':'W;F','Impossible WHERE':'I'}
plan_table=[]
for pair in zip(*full_plans):
    cells=[]
    for row in pair:
        cells += ['d2' if row['table']=='<derived2>' else row['table'],row['type'],key_aliases[row['key']],row['rows'],extra_aliases[row['Extra']]]
    plan_table.append(cells)
checks['tables']['EXPLAIN_rows_per_plan']=7
TABLES['explain']=table(['Cu: nod','type','key','n','X','Fără: nod','type','key','n','X'],plan_table,[49,39,42,36,WIDTH/2-166]*2)

timeline=(ROOT/'03_timeline.sql').read_text()
def block(event):return re.search(r'-- BEGIN EVENT '+event+r':.*?-- END EVENT '+event,timeline,re.S)[0]
def lines_matching(event,prefixes):
    return [line for line in block(event).splitlines() if any(line.startswith(p) for p in prefixes)]
def formatted_sql(lines):
    # Only whitespace is inserted. Full executable statements remain in source SQL.
    text='\n'.join(lines).replace(',',', ')
    return '\n'.join('\n'.join(textwrap.wrap(line,width=106,subsequent_indent='  ',break_long_words=False,break_on_hyphens=False)) for line in text.splitlines())
code={
 'sql_common':formatted_sql(lines_matching('T18',["SET @sim_now='",'SET v_time=','INSERT INTO tx_registry(','SET @write_tx_id=','INSERT INTO tx_event_tag('])),
 'sql_t18':formatted_sql(lines_matching('T18',['UPDATE head_coach_role_version','INSERT INTO head_coach_role_version'])),
 'sql_t19':formatted_sql(lines_matching('T19',["SET @sim_now='",'SET v_time=','UPDATE head_coach_role_version','INSERT INTO head_coach_role_version'])),
 'sql_t25':formatted_sql(lines_matching('T25',["SET @sim_now='",'SET v_time=','UPDATE contract_version'])),
 'sql_finish':formatted_sql(lines_matching('T25',['SELECT COUNT(*) INTO v_q0','IF NOT COALESCE((v_q0=0)','COMMIT;']))}
references=Paragraph('Referințe: Assignment1, pp. 2–7; Course1, pp. 12, 29–42. [R1] <link href="https://docs.oracle.com/en/database/oracle/oracle-database/26/adfns/flashback.html">Oracle: Flashback / Temporal Validity</link>. [R2] <link href="https://learn.microsoft.com/en-us/sql/relational-databases/tables/temporal-tables">Microsoft: Temporal tables</link> și <link href="https://learn.microsoft.com/en-us/sql/relational-databases/tables/temporal-table-considerations-and-limitations">limitations</link>. [R3] <link href="https://www.postgresql.org/docs/18/sql-createtable.html">PostgreSQL 18 CREATE TABLE</link>. [R4] <link href="https://www.postgresql.org/docs/19/ddl-temporal-tables.html">PostgreSQL 19 temporal tables</link> / <link href="https://www.postgresql.org/docs/19/sql-update.html">UPDATE</link>, consultate în auditul final. Proveniență detaliată: docs/report_evidence_map.md; rezultate și parametri: evidence/replay/.',styles['small'])
runmanifest=json.loads((E/'manifest.json').read_text()) if (E/'manifest.json').exists() else {}
fresh=runmanifest.get('status')=='PASS' and runmanifest.get('positive_scenarios')==52
reference=ROOT/'evidence/business_normalized_reference.json'
if not reference.exists():reference=ROOT/'submission/boar_victor/evidence/business_normalized_reference.json'
business_reference=json.loads(reference.read_text())
for key,count in {'player':60,'coach':8,'club':6,'contract':69,'club_version':18,'contract_version':98,'head_coach_role_version':15,'tx_registry':38,'tx_event_tag':53}.items():
    if len(business_reference[key])!=count:raise RuntimeError('Dataset narrative mismatch: '+key)
naive='O capcană conceptuală este Q2 cu DISTINCT fără coalescing: identități distincte de rând nu reunesc un mandat continuu. Această observație nu este prezentată ca încercare executată anterior.'
if (E/'q2_without_coalescing.json').exists():
    demo=json.loads((E/'q2_without_coalescing.json').read_text())
    if demo['naive_mismatch_demonstrated']:naive='Auditul final demonstrează read-only și Q2 cu DISTINCT fără coalescing: două rânduri H05 în loc de un mandat. Actual și expected independente sunt în q2_without_coalescing.json; demonstrația aparține auditului, nu unui istoric inventat al dezvoltării.'
replacements={'evaluation_date':q1[0]['evaluation_date'],'elapsed_days':q2[0]['elapsed_days'],'run_description':'rularea nouă a pachetului a trecut 52 scenarii pozitive și 4 verificări Q0' if fresh else 'capturile provin din replay-ul anterior verificat (fără a pretinde o rerulare)','naive_demo_description':naive}
source=(ROOT/'docs/report.md').read_text()
for key,value in replacements.items():source=source.replace('{{'+key+'}}',value)
pages=[section.strip() for section in re.split(r'<!-- PAGE \d+ -->',source) if section.strip()]
if len(pages)!=5:raise RuntimeError('Source must define exactly five pages')
C=canvas.Canvas(str(OUT),pagesize=A4,invariant=1,pageCompression=1,initialFontName='Body',initialFontSize=10.1,lang='ro-RO')
C.setTitle('Two Clocks — Boar Victor');C.setAuthor('Boar Victor');C.setSubject('Assignment 1 — core A–D; MariaDB 11.8.8')
for number,page in enumerate(pages,1):
    y=TOP;placed=[]
    for part in re.split(r'\n\s*\n',page):
        part=part.strip()
        if not part:continue
        token=re.fullmatch(r'\{\{(\w+)\}\}',part)
        if token:
            key=token[1]
            obj=TABLES[key] if key in TABLES else Preformatted(code[key],styles['code']) if key in code else references
            gap=3
        elif part.startswith('#'):
            match=re.match(r'(#+)\s+(.*)',part,re.S);style='h'+str(min(len(match[1]),3));obj=par(match[2].replace('\n',' '),style);gap=styles[style].spaceAfter
        else:obj=par(part.replace('\n',' '));gap=4
        w,h=obj.wrap(WIDTH,10000)
        if w>WIDTH+1 or y-h<BOTTOM:raise RuntimeError(f'Page {number} overflow: y={y:.1f}, h={h:.1f}, width={w:.1f}; {part[:90]}')
        obj.drawOn(C,LEFT,y-h)
        placed.append({'text':part[:70],'top':round(y,2),'height':round(h,2),'width':round(w,2)})
        y-=h+gap
    C.setFont('Body',8);C.setFillColor(colors.HexColor('#64748b'));C.drawString(LEFT,16,'Two Clocks · Boar Victor');C.drawRightString(A4[0]-LEFT,16,f'{number} / 5');C.setFillColor(colors.black)
    checks['pages'].append({'page':number,'content_bottom':round(y,2),'objects':placed});C.showPage()
C.save()
checks['pdf_sha256']=sha(OUT);checks['source_sha256']=sha(ROOT/'docs/report.md');checks['evidence_root']=str(E)
audit_dir=args.audit_dir.resolve() if args.audit_dir else ROOT/'verification/phase4' if (ROOT/'verification').exists() else ROOT/'evidence'
audit_dir.mkdir(parents=True,exist_ok=True)
(audit_dir/'report_layout.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n')
print('PASS: five-page report, tables checked against CSV, all fonts ≥8 pt: '+str(OUT))
