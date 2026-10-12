"""Deterministic authoring tool. Emitted SQL is standalone; no Python required for 01->02->03."""
from pathlib import Path
from datetime import date,timedelta,datetime
import json,csv
R=Path(__file__).resolve().parents[1]
INF='9999-12-31'; TT='9999-12-31 23:59:59.999999'
def q(v): return "'"+str(v).replace("'","''")+"'"
# Literal authored event plan. No random scenario generation.
raw=[
('2025-07-01 09:00:00','E1','initial','2025-07-01',{},'Încărcare inițială: persoane fictive, cluburi, două sezoane, contracte și titulari; CL04 are două angajamente adiacente cu H05.'),
('2025-09-10 14:00:00','E3','transfer','2025-08-31',dict(p='P001',club='CL01',dest='CL06',old=1010,new=1510),'Transfer P001 la FC Târnava, înregistrat după închiderea ferestrei fictive.'),
('2025-09-15 14:00:00','E3','transfer','2025-08-30',dict(p='P002',club='CL01',dest='CL02',old=1020,new=1520),'Transfer P002 la FC Ardeal, înregistrat târziu.'),
('2025-09-22 14:00:00','E3','transfer','2025-08-29',dict(p='P003',club='CL01',dest='CL03',old=1030,new=1530),'Transfer P003 la FC Mureș, înregistrat târziu.'),
('2025-10-05 10:00:00','E2','budget','2025-11-01',dict(club='CL01',old=1000000,new=1100000),'FC Someș anunță majorarea bugetului pentru noiembrie.'),
('2025-10-12 14:00:00','E3','transfer','2025-08-28',dict(p='P004',club='CL01',dest='CL04',old=1040,new=1540),'Transfer P004 la FC Apuseni, înregistrat târziu.'),
('2025-10-20 14:00:00','E3','transfer','2025-08-27',dict(p='P005',club='CL01',dest='CL05',old=1050,new=1550),'Transfer P005 la FC Criș, înregistrat târziu.'),
('2025-11-10 10:00:00','E2','budget','2025-12-01',dict(club='CL02',old=1100000,new=1200000),'FC Ardeal anunță bugetul din decembrie.'),
('2025-12-01 10:00:00','E2','budget','2026-01-01',dict(club='CL03',old=1200000,new=1300000),'FC Mureș anunță bugetul din ianuarie.'),
('2025-12-03 14:00:00','E5','end','2025-12-01',dict(p='P013',club='CL02',old=1130),'P013 părăsește real CL02 la 1 decembrie.'),
('2025-12-18 14:00:00','E5','end','2025-12-15',dict(p='P014',club='CL02',old=1140),'P014 părăsește real CL02 la 15 decembrie.'),
('2025-12-23 14:00:00','E5','end','2025-12-20',dict(p='P015',club='CL02',old=1150),'P015 părăsește real CL02 la 20 decembrie.'),
('2026-01-08 14:00:00','E3,E5','end','2026-01-01',dict(p='P016',club='CL02',old=1160),'Plecare P016 de la CL02, înregistrată cu șapte zile întârziere.'),
('2026-01-18 14:00:00','E5','end','2026-01-15',dict(p='P017',club='CL02',old=1170),'P017 părăsește real CL02 la 15 ianuarie.'),
('2026-01-20 10:00:00','E2,E6','restart','2026-02-01',dict(p='P013',club='CL02',new=1130,kind='PERMANENT',end=INF),'Revenirea P013 este anunțată pentru februarie, pe aceeași ancoră.'),
('2026-01-20 14:00:00','E3,E7','role','2026-01-10',dict(club='CL02',old='H03',new='H08'),'H08 îl înlocuiește pe H03 la CL02 din 10 ianuarie.'),
('2026-02-15 10:00:00','E2,E6','restart','2026-03-01',dict(p='P014',club='CL02',new=1140,kind='PERMANENT',end=INF),'Revenirea P014 la CL02 este anunțată pentru martie.'),
('2026-03-10 14:00:00','E3,E7','role','2026-03-01',dict(club='CL01',old='H01',new='H02'),'CL01 înregistrează demiterea/înlocuirea H01 cu H02, inițial datată 1 martie.'),
('2026-03-15 11:00:00','E3,E4','role_correction','2026-03-03',dict(club='CL01',old='2026-03-01',new='2026-03-03'),'Corecție T18: data reală a înlocuirii este 3 martie, nu 1 martie.'),
('2026-03-20 14:00:00','E3,E6','restart','2026-03-10',dict(p='P015',club='CL02',new=1150,kind='PERMANENT',end=INF),'P015 revine la CL02 după pauză; revenirea este înregistrată târziu.'),
('2026-04-10 14:00:00','E3','loan','2026-04-01',dict(p='P060',club='CL06',new=600,kind='LOAN',end='2026-05-01'),'Afirmație eronată: P060 ar fi împrumutat la CL06 în aprilie.'),
('2026-04-15 10:00:00','E2','salary','2026-05-01',dict(p='P025',club='CL03',old=1250,new=1450),'Salariul P025 va crește din mai; se păstrează prefixul cu 1250 EUR.'),
('2026-04-20 10:00:00','E3,E4','salary_correction','2025-07-01',dict(p='P026',club='CL03',old=1260,new=1280),'Corectează salariul inițial P026 la 1280 EUR.'),
('2026-04-22 10:00:00','E3,E4','salary_correction','2025-07-01',dict(p='P027',club='CL03',old=1270,new=1290),'Corectează salariul inițial P027 la 1290 EUR.'),
('2026-04-25 10:00:00','E8','retract','2026-04-01',dict(p='P060',club='CL06',old=600),'Retrage T21 ca niciodată adevărat; închide numai TT, fără înlocuire.'),
('2026-05-10 10:00:00','E3,E4','salary_correction','2026-05-01',dict(p='P025',club='CL03',old=1450,new=1455),'Corectează T22 numai în sufixul din mai; prefixul anterior rămâne.'),
('2026-05-15 10:00:00','E2','salary','2026-06-01',dict(p='P026',club='CL03',old=1280,new=1480),'Anunță salariul P026 din iunie, plecând de la valoarea corectată.'),
('2026-06-10 10:00:00','E3','loan','2026-06-01',dict(p='P006',club='CL02',new=600,kind='LOAN',end='2026-09-01'),'Împrumut P006 la CL02 până în septembrie, fără închiderea contractului de origine.'),
('2026-06-10 11:00:00','E3','loan','2026-06-01',dict(p='P007',club='CL03',new=700,kind='LOAN',end='2026-09-01'),'Împrumut P007 la CL03, înregistrat cu nouă zile întârziere.'),
('2026-06-10 12:00:00','E3','loan','2026-06-01',dict(p='P008',club='CL04',new=800,kind='LOAN',end='2026-09-01'),'Împrumut P008 la CL04, înregistrat cu nouă zile întârziere.'),
('2026-06-15 10:00:00','E2','salary','2026-07-01',dict(p='P027',club='CL03',old=1290,new=1490),'Anunță salariul P027 din iulie, păstrând valoarea inițială corectată.'),
('2026-07-05 10:00:00','E5','end','2026-07-01',dict(p='P006',club='CL02',old=600),'Scurtează real împrumutul P006: se încheie la 1 iulie, nu 1 septembrie.'),
('2026-07-10 10:00:00','E3,E4','salary_correction','2026-07-01',dict(p='P027',club='CL03',old=1490,new=1495),'Corectează T31 numai în sufixul din iulie la 1495 EUR.'),
('2026-07-15 10:00:00','E2,E9','multi','2026-08-01',dict(club='CL04',p='P037',old=1300000,new=1430000,salary_old=1370,salary_new=1570),'O singură decizie majorează bugetul CL04 și salariul P037 din august.'),
('2026-08-15 10:00:00','E2,E9','multi','2026-09-01',dict(club='CL05',p='P049',old=1400000,new=1540000,salary_old=1490,salary_new=1740),'O singură decizie majorează bugetul CL05 și salariul P049 din septembrie.'),
('2026-09-01 10:00:00','E2,E7','role','2026-10-01',dict(club='CL03',old='H04',new='H01'),'H01 este anunțat la CL03 din octombrie, după plecarea din CL01.'),
('2026-09-10 10:00:00','E2','budget','2026-11-01',dict(club='CL06',old=1500000,new=1650000),'CL06 anunță bugetul din noiembrie înainte să devină valabil.'),
('2026-09-20 10:00:00','E2,E6','restart','2026-10-01',dict(p='P006',club='CL02',new=650,kind='LOAN',end='2026-12-01'),'Reîncepe împrumutul P006 pe aceeași ancoră, după pauza iulie–octombrie.')]
events=[]
for n,(time,tags,op,eff,detail,desc) in enumerate(raw,1):
 events.append(dict(event_ref=f'T{n:02}',tx_time_utc=time+'.000000',event_tags=tags.split(','),primary_operation=op,effective_from=eff,effective_to=detail.get('end',''),delay_days=(date.fromisoformat(time[:10])-date.fromisoformat(eff)).days,description=desc,**detail))
(R/'docs/timeline_plan.json').write_text(json.dumps(events,ensure_ascii=False,indent=2)+'\n')
versions={
'club_version':['version_id','club_id','club_name','budget_eur','valid_from','valid_to','tx_from','tx_to','tx_id'],
'contract_version':['version_id','contract_id','agreement_kind','salary_eur','valid_from','valid_to','tx_from','tx_to','tx_id'],
'head_coach_role_version':['version_id','role_id','coach_id','valid_from','valid_to','tx_from','tx_to','tx_id']}
def check(expr,msg):return f"IF NOT COALESCE(({expr}),0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT={q('P2_ASSERT: '+msg)}; END IF;"
def affected(n): return check(f'ROW_COUNT()={n}',f'expected {n} affected rows')
def header(initial):
 s="""-- Part B, standalone MariaDB SQL. Select database in the client; no hardcoded USE.
-- Fresh connection, fail-fast, NEVER --force. No persistent helper DDL/API.
-- E1/T01 is exclusively in 02_data.sql; T02-T38 exclusively in 03_timeline.sql.
SET NAMES utf8mb4;
SET SESSION time_zone='+00:00';
SET SESSION sql_mode='STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET @sim_now=NULL, @write_tx_id=NULL;
DELIMITER $$
BEGIN NOT ATOMIC
 IF DATABASE() IS NULL OR @@in_transaction THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='P2_PRECONDITION: select database and use a fresh connection'; END IF;
END$$
DELIMITER ;
"""
 for t in versions:s+=f'CREATE TEMPORARY TABLE p2_before_{t} LIKE {t};\n'
 return s

def prefix(e):
 ref=e['event_ref'];n=int(ref[1:]);s=[f"\n-- BEGIN EVENT {ref}: {','.join(e['event_tags'])} / {e['primary_operation']}\n-- {e['description']}\nSET NAMES utf8mb4;\nSET SESSION time_zone='+00:00';\nDELIMITER $$\nBEGIN NOT ATOMIC",
 "DECLARE v_time DATETIME(6);\nDECLARE v_id BIGINT UNSIGNED;\nDECLARE v_old BIGINT UNSIGNED;\nDECLARE v_old2 BIGINT UNSIGNED;\nDECLARE v_locked BIGINT UNSIGNED;\nDECLARE v_q0 BIGINT;\nDECLARE v_errno INT;\nDECLARE v_message TEXT;\nDECLARE v_got_lock INT DEFAULT 0;",
 f"""DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO, v_message=MESSAGE_TEXT;
  ROLLBACK;
  SET @sim_now=NULL, @write_tx_id=NULL;
  IF v_got_lock=1 THEN DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay')); END IF;
  SELECT {q(ref)} AS failed_event, v_errno AS error_code, v_message AS error_message,
         (SELECT MAX(LEFT(reason,3)) FROM tx_registry) AS last_committed_event;
  RESIGNAL;
 END;
 SET v_got_lock=GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0);
 {check('v_got_lock=1','another replay is active')}
 START TRANSACTION;"""]
 # Replay locks all anchors: small fixed dataset, explicit common order, all relevant parents covered.
 for t,key in [('club','club_id'),('player','player_id'),('coach','coach_id'),('contract','contract_id'),('head_coach_role','role_id')]:
  s.append(f"""BEGIN
 DECLARE done INT DEFAULT 0;
 DECLARE anchor_cursor CURSOR FOR SELECT {key} FROM {t} ORDER BY {key} FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
 OPEN anchor_cursor;
 lock_loop: LOOP
  FETCH anchor_cursor INTO v_locked;
  IF done THEN LEAVE lock_loop; END IF;
 END LOOP;
 CLOSE anchor_cursor;
END;""")
 if n==1:
  s.append(check(' + '.join(f'(SELECT COUNT(*) FROM {t})' for t in ['player','coach','club','season','contract','head_coach_role','tx_registry','tx_event_tag',*versions])+'=0','T01 requires an unpopulated database; refusing duplicate load'))
  s.append(check('(SELECT COUNT(*) FROM query_params)=1','query_params singleton required'))
 else:
  s.append(check(f'(SELECT COUNT(*) FROM tx_registry)={n-1} AND (SELECT COUNT(*) FROM tx_registry WHERE LEFT(reason,3)={q(f"T{n-1:02}")})=1',f'{ref} requires exactly prefix T01-T{n-1:02}; no automatic resume'))
  s.append(check(f'(SELECT MAX(tx_time) FROM tx_registry)<{q(e["tx_time_utc"])}',f'{ref} transaction order'))
 for t in versions:s.append(f'DELETE FROM p2_before_{t};\nINSERT INTO p2_before_{t} SELECT * FROM {t};')
 s.extend([f'SET @sim_now={q(e["tx_time_utc"])};', 'SET v_time=fn_effective_time();',f'INSERT INTO tx_registry(tx_time,author,reason) VALUES(v_time,\'Boar Victor — dataset fictiv\',{q(ref+": "+e["description"])});','SET @write_tx_id=LAST_INSERT_ID();', 'INSERT INTO tx_event_tag(tx_id,event_code) VALUES '+','.join(f'(@write_tx_id,{q(tag)})' for tag in e['event_tags'])+';'])
 return s

def suffix(e):
 s=[]
 for t,cols in versions.items():
  comparisons=[]
  for c in cols:
   if c=='tx_to':continue
   comparisons.append(f'NOT (BINARY b.{c} <=> BINARY a.{c})' if c in ['club_name','agreement_kind'] else f'NOT (b.{c} <=> a.{c})')
  comparisons.append(f"(b.tx_to <> {q(TT)} AND a.tx_to<>b.tx_to)")
  comparisons.append(f"(b.tx_to = {q(TT)} AND a.tx_to<>b.tx_to AND a.tx_to<>v_time)")
  s.append(check(f"NOT EXISTS(SELECT 1 FROM p2_before_{t} b LEFT JOIN {t} a USING(version_id) WHERE a.version_id IS NULL OR "+' OR '.join(comparisons)+')',f'{e["event_ref"]} I4 {t} unchanged except legitimate close'))
  s.append(check(f'NOT EXISTS(SELECT 1 FROM {t} a JOIN tx_registry r USING(tx_id) WHERE a.tx_from<>r.tx_time OR a.tx_from>UTC_TIMESTAMP(6) OR a.tx_from>=a.tx_to)',f'{t} registry time and order'))
 s.extend(['SELECT COUNT(*) INTO v_q0 FROM v_integrity_violations;',check('v_q0=0',e['event_ref']+' Q0 violations -> rollback'),f"SELECT {q(e['event_ref'])} AS event_ref,@write_tx_id AS tx_id,v_time AS tx_time_utc,v_q0 AS q0_violations,'PASS' AS i4_snapshot;",'COMMIT;',"SET @sim_now=NULL, @write_tx_id=NULL;", "DO RELEASE_LOCK(CONCAT(DATABASE(),':phase2_replay'));",f"SELECT {q(e['event_ref'])} AS committed_event;",'END$$\nDELIMITER ;',f'-- END EVENT {e["event_ref"]}\n'])
 return s

def footer():return '\n'.join(f'DROP TEMPORARY TABLE p2_before_{t};' for t in versions)+'\nSET @sim_now=NULL, @write_tx_id=NULL;\n'
def contract_key(p,c):return f"(SELECT a.contract_id FROM contract a JOIN player p USING(player_id) JOIN club c USING(club_id) WHERE p.player_code={q(p)} AND c.club_code={q(c)})"
def club_key(c):return f'(SELECT club_id FROM club WHERE club_code={q(c)})'
def coach_key(c):return f'(SELECT coach_id FROM coach WHERE coach_code={q(c)})'
def role_key(c):return f'(SELECT role_id FROM head_coach_role WHERE club_id={club_key(c)})'
def select_old(t,key,eff):
 return [f"SET v_old=(SELECT version_id FROM {t} WHERE {key} AND valid_from<={q(eff)} AND {q(eff)}<valid_to AND tx_to={q(TT)});",check('v_old IS NOT NULL',t+' expected one current affected version')]
def close(t,where='version_id=v_old',n=1):return [f'UPDATE {t} SET tx_to=v_time WHERE {where} AND tx_to={q(TT)};',affected(n)]
def copy_insert(t,exprs,where='version_id=v_old'):
 cols=[c for c in versions[t] if c!='version_id']
 values=[exprs.get(c,{'tx_from':'v_time','tx_to':q(TT),'tx_id':'@write_tx_id'}.get(c,c)) for c in cols]
 return [f"INSERT INTO {t}({','.join(cols)}) SELECT {','.join(values)} FROM {t} WHERE {where};",affected(1)]
def new_contract(p,c,kind,salary,start,end):
 return [f"INSERT INTO contract_version(contract_id,agreement_kind,salary_eur,valid_from,valid_to,tx_from,tx_id) VALUES({contract_key(p,c)},{q(kind)},{salary:.2f},{q(start)},{q(end)},v_time,@write_tx_id);",affected(1)]
def anchor(p,c):return [f"INSERT INTO contract(player_id,club_id) SELECT p.player_id,c.club_id FROM player p CROSS JOIN club c WHERE p.player_code={q(p)} AND c.club_code={q(c)};",affected(1)]
def numeric(e,table,old,new):
 key=('club_id='+club_key(e['club'])) if table=='club_version' else ('contract_id='+contract_key(e['p'],e['club']))
 field='budget_eur' if table=='club_version' else 'salary_eur'
 out=select_old(table,key,e['effective_from'])
 out.append(check(f'(SELECT {field} FROM {table} WHERE version_id=v_old)={old}',f'{table} expected old numeric value'))
 out+=close(table)
 out+=copy_insert(table,{'valid_to':q(e['effective_from'])})
 out+=copy_insert(table,{'valid_from':q(e['effective_from']),field:f'{new:.2f}'})
 return out
# T01 materialized values, no runtime generator.
e=events[0];s=[header(True)]+prefix(e)
players=[]
for n in range(1,61):players.append(f"({q(f'P{n:03}')},{q(f'Jucător Fictiv {n:03}')},{q(date(1995,1,1)+timedelta(days=37*(n-1)))})")
s+=['INSERT INTO player(player_code,full_name,birth_date) VALUES\n'+',\n'.join(players)+';',affected(60)]
coaches=['Andrei Ionescu','Mihai Popescu','Radu Marin','Vlad Stan','Sorin Dima','Dan Rusu','Paul Muntean','Alex Matei']
s+=['INSERT INTO coach(coach_code,full_name,birth_date) VALUES\n'+',\n'.join(f"({q(f'H{n:02}')},{q(name)},{q(f'{1969+n}-01-01')})" for n,name in enumerate(coaches,1))+';',affected(8)]
clubs=['FC Someș','FC Ardeal','FC Mureș','FC Apuseni','FC Criș','FC Târnava']
s+=['INSERT INTO club(club_code) VALUES '+','.join(f'({q(f"CL{n:02}")})' for n in range(1,7))+';',affected(6),"INSERT INTO season(season_name,period_start,period_end) VALUES ('2025/2026','2025-07-01','2026-07-01'),('2026/2027','2026-07-01','2027-07-01');",affected(2)]
for n,name in enumerate(clubs,1):
 s.append(f"INSERT INTO club_version(club_id,club_name,budget_eur,valid_from,tx_from,tx_id) VALUES({club_key(f'CL{n:02}')},{q(name)},{900000+n*100000}.00,'2025-07-01',v_time,@write_tx_id);")
for n in range(1,61):
 p=f'P{n:03}';c=f'CL{(n-1)//12+1:02}'
 s+=anchor(p,c)+new_contract(p,c,'PERMANENT',1000+10*n,'2025-07-01',INF)
for n,h in enumerate([1,3,4,5,6,7],1):
 c=f'CL{n:02}'
 s.append(f'INSERT INTO head_coach_role(club_id) VALUES({club_key(c)});')
 for start,end in ([('2025-07-01','2026-07-01'),('2026-07-01',INF)] if n==4 else [('2025-07-01',INF)]):
  s.append(f"INSERT INTO head_coach_role_version(role_id,coach_id,valid_from,valid_to,tx_from,tx_id) VALUES({role_key(c)},{coach_key(f'H{h:02}')},{q(start)},{q(end)},v_time,@write_tx_id);")
s.append(check('(SELECT COUNT(*) FROM club_version)=6 AND (SELECT COUNT(*) FROM contract_version)=60 AND (SELECT COUNT(*) FROM head_coach_role_version)=7','T01 exactly 73 versions'))
s.append(f"UPDATE query_params SET subject_id={club_key('CL01')} WHERE params_id=1;")
s+=suffix(e)+[footer()]
(R/'02_data.sql').write_text('\n'.join(s))
s=[header(False)]
for e in events[1:]:
 s+=prefix(e);op=e['primary_operation'];eff=e['effective_from'];c=e['club'];p=e.get('p')
 if op=='transfer':
  s+=select_old('contract_version','contract_id='+contract_key(p,c),eff)+close('contract_version')+copy_insert('contract_version',{'valid_to':q(eff)})
  s+=anchor(p,e['dest'])+new_contract(p,e['dest'],'PERMANENT',e['new'],eff,INF)
 elif op=='end':
  s+=select_old('contract_version','contract_id='+contract_key(p,c),eff)+close('contract_version')+copy_insert('contract_version',{'valid_to':q(eff)})
 elif op in ['restart','loan']:
  if op=='loan':s+=anchor(p,c)
  else:s.append(check(f'{contract_key(p,c)} IS NOT NULL','restart reuses existing anchor'))
  s+=new_contract(p,c,e['kind'],e['new'],eff,e['end'])
 elif op=='budget':s+=numeric(e,'club_version',e['old'],e['new'])
 elif op=='salary':s+=numeric(e,'contract_version',e['old'],e['new'])
 elif op=='multi':s+=numeric(e,'club_version',e['old'],e['new'])+numeric(e,'contract_version',e['salary_old'],e['salary_new'])
 elif op=='salary_correction':
  s+=select_old('contract_version','contract_id='+contract_key(p,c),eff)
  s.append(check(f'(SELECT salary_eur FROM contract_version WHERE version_id=v_old)={e["old"]}','correction expected wrong salary'))
  s+=close('contract_version')+copy_insert('contract_version',{'salary_eur':f'{e["new"]:.2f}'})
 elif op=='retract':
  s+=select_old('contract_version','contract_id='+contract_key(p,c),eff)+close('contract_version')
 elif op=='role':
  s+=select_old('head_coach_role_version','role_id='+role_key(c),eff)
  s.append(check(f'(SELECT coach_id FROM head_coach_role_version WHERE version_id=v_old)={coach_key(e["old"])}','expected old coach'))
  s+=close('head_coach_role_version')+copy_insert('head_coach_role_version',{'valid_to':q(eff)})+copy_insert('head_coach_role_version',{'valid_from':q(eff),'coach_id':coach_key(e['new'])})
 elif op=='role_correction':
  s.append(f"SET v_old=(SELECT version_id FROM head_coach_role_version WHERE role_id={role_key(c)} AND coach_id={coach_key('H01')} AND tx_to={q(TT)});")
  s.append(f"SET v_old2=(SELECT version_id FROM head_coach_role_version WHERE role_id={role_key(c)} AND coach_id={coach_key('H02')} AND tx_to={q(TT)});")
  s.append(check('v_old IS NOT NULL AND v_old2 IS NOT NULL','T19 two current beliefs'))
  s+=close('head_coach_role_version','version_id IN(v_old,v_old2)',2)
  s+=copy_insert('head_coach_role_version',{'valid_to':q(eff)})+copy_insert('head_coach_role_version',{'valid_from':q(eff)},'version_id=v_old2')
 if e['event_ref']=='T38':
  s.append(f"UPDATE query_params SET valid_at='2026-03-02',known_at='2026-03-16 12:00:00.000000',period_start='2025-07-01',period_end='2026-07-01',subject_id={club_key('CL01')} WHERE params_id=1;")
 s+=suffix(e)
s.append(footer());(R/'03_timeline.sql').write_text('\n'.join(s))
print('Generated 02_data.sql, 03_timeline.sql, timeline_plan.json; 38 authored events')
