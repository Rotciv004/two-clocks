<!-- PAGE 1 -->
# Two Clocks — o ligă fictivă cu memorie bitemporală

Boar Victor · Advanced Database Chapters and Cloud Databases · MariaDB 11.8.8

## 1. Domeniu și importanța timpului

Liga fictivă urmărește jucători, cluburi și antrenori, contracte permanente, împrumuturi și bugete. Un contract poate înceta și reîncepe pe aceeași pereche; un salariu sau buget poate fi anunțat pentru viitor. O înregistrare întârziată ori o corecție schimbă ceea ce știe baza despre trecut. Data realității și data cunoașterii trebuie păstrate separat pentru audit, salarizare și reconstruirea deciziilor luate cu informația disponibilă atunci.

Întrebarea centrală este „Cine antrena FC Someș (CL01) la 2 martie 2026?”. La 5 martie, baza îl considera titular pe H01, Andrei Ionescu. La 10 martie a fost înregistrată înlocuirea cu H02, Mihai Popescu, efectivă de la 1 martie: perspectiva din 12 martie îl indică pe H02. La 15 martie se corectează data efectivă la 3 martie; perspectiva din 16 martie îl indică din nou pe H01. Q6 returnează A→B→A pentru aceeași dată VT, din trei momente TT. Sunt trei răspunsuri corecte în contexte de cunoaștere diferite; nu sunt trei persoane distincte.

Același mecanism explică transferul P001: noua relație devine valabilă la 31 august 2025, dar este înregistrată abia la 10 septembrie, după închiderea ferestrei fictive. O analiză construită din cunoașterea de la începutul lui septembrie trebuie să păstreze atunci vechea credință. Salariile și bugetele anunțate anticipat introduc și fapte viitoare în baza curentă, fără ca acestea să fie deja active în ziua înregistrării.

Împrumuturile pot coexista cu relația permanentă de origine. Pentru P006, încetarea efectivă a primului împrumut și revenirea după o pauză formează perioade diferite pe aceeași ancoră. Un număr de contracte „curente în TT” include și intervale finite deja încheiate, deoarece baza continuă să le considere fapte adevărate. Numărul activ într-o zi sau într-o lună cere suplimentar filtrul VT; această alegere explică diferența dintre Q1, Q5 și Q7.

Pentru audit este necesară atât situația reală reconstruită cu toate corecțiile cunoscute azi, cât și informația disponibilă când s-a luat o decizie. Corectarea unei date nu trebuie să facă imposibilă justificarea unei decizii anterioare. Domeniul fictiv permite proiectarea deliberată a acestor cazuri: transfer întârziat, împrumut scurtat, demitere cu dată disputată și retractarea unei afirmații false.

Datasetul final verificat conține 60 jucători, 8 antrenori, 6 cluburi, 69 ancore contractuale și 131 versiuni: 18 de club, 98 contractuale și 15 de rol. Cele 38 de schimbări au 53 de etichete E1–E9. Sunt 77 fapte contractuale curente în TT; unele descriu VT încheiat sau viitor. Sezoanele numite sunt 2025/2026 și 2026/2027, fiecare `[1 iulie,1 iulie anul următor)`.

## 2. Decizii de modelare

VT folosește `DATE`, deoarece contractele și mandatele au granularitate zilnică. TT folosește `DATETIME(6)` UTC. Sesiunile execută `SET time_zone='+00:00'`; DATETIME stochează valoarea convenită, fără conversie implicită de fus orar. Capetele deschise sunt santinelele exacte `9999-12-31` și `9999-12-31 23:59:59.999999`. Ele evită ramurile speciale pentru NULL; NULL din durata unui mandat deschis indică durata totală necunoscută, nu un capăt al perioadei.

Ambele axe sunt semi-deschise `[start,end)`, cu CHECK strict `from < to`. Predicatul de punct este `valid_from <= valid_at AND valid_at < valid_to AND tx_from <= known_at AND known_at < tx_to`. Frontierele adiacente se întâlnesc fără suprapunere; BETWEEN ar include greșit ambele capete. PK-ul `version_id` identifică rândul fizic; cheia de business este `club_id`, `contract_id` sau `role_id`.

Șase ancore netemporale separă identitățile de cele trei versiuni bitemporale: `club_version` (nume/buget), `contract_version` (tip/salariu), `head_coach_role_version` (titular). `UNIQUE(player_id,club_id)` păstrează ancora la reveniri; `UNIQUE(club_id)` păstrează poziția stabilă de antrenor. FK-urile obișnuite indică ancorele și registrul. Identitățile și numele persoanelor sunt fixe în acest domeniu; `season` este o definiție fixă a perioadei de analiză.

`tx_registry(tx_id,tx_time,author,reason)` păstrează un moment comun pentru fiecare schimbare. `tx_event_tag` permite etichete multiple, inclusiv E9 pe două tabele, fără dublarea `(tx_id,event_code)`. Aceste două tabele și singletonul `query_params` sunt tehnice, netemporale; un timestamp auxiliar nu le versionează. `subject_id` se interpretează per view și nu primește un FK arbitrar.

Core track folosește modelul manual acceptat de assignment, cu `fn_effective_time()` care citește `@sim_now` valid sau `UTC_TIMESTAMP(6)`. @sim_now este ceasul aplicației, nu ceasul SYSTEM VERSIONING. Trigger-ele protejează istoricul; I1–I3 sunt verificate prin Q0 și protocol. Scrierea directă a TT în scripturi înseamnă că bonusul A1 nu este îndeplinit. A2 nativ nu este implementat. Diagrama separată `er_diagram.pdf`/PNG/DOT prezintă toate cele 12 tabele, PK/FK/UQ și cardinalitățile crow’s-foot.

<!-- PAGE 2 -->
## 3. Protocol de scriere — E3, E4 și E8

Fragmentele sunt din T18/T19/T25, pentru clone de replay aflate exact după T17/T18/T24. Codul complet executabil este `docs/report_write_examples.sql` (blocuri copiate integral din `03_timeline.sql`). El rezolvă ancorele prin CL01/H01/H02 sau P060/CL06, blochează ancorele în ordinea club→player→coach→contract→rol, capturează `v_time` o singură dată și verifică prefixul cronologiei. `v_old/v_old2` provin din SELECT-uri pe coduri și versiunile curente; nu sunt ID-uri presupuse.

Fiecare bloc are START TRANSACTION și handler EXIT cu ROLLBACK/RESIGNAL. Registrul și toate etichetele sunt inserate înaintea versiunilor; snapshot-urile I4, numărul rândurilor afectate și Q0 zero preced COMMIT. GET_LOCK serializează replay-urile cooperante. Protocolul de ancore este documentat; concurența între sesiuni nu a fost testată.

{{sql_common}}

### E3/T18 — înlocuirea înregistrată târziu

La TT `2026-03-10 14:00:00` UTC, H02 îl înlocuiește pe H01 de la VT `2026-03-01`. Versiunea veche se închide numai în TT; noile credințe sunt prefixul H01 și sufixul H02.

{{sql_t18}}

### E4/T19 — corecția frontierei 1→3 martie

La TT `2026-03-15 11:00:00` UTC, se închid ambele credințe afectate și se inserează cele două corectate. VT și titularul rândurilor vechi rămân nemodificate. Secvența registrului de mai sus se repetă cu motivul T19 și etichetele E3/E4.

{{sql_t19}}

### E8/T25 — retractarea „niciodată adevărat”

La TT `2026-04-25 10:00:00` UTC, `v_old` este împrumutul P060–CL06 `[2026-04-01,2026-05-01)`. Registrul T25 primește E8, iar închiderea de mai jos nu are replacement:

{{sql_t25}}

Finalul comun verifică integritatea înainte de commit (orice eroare activează handlerul ROLLBACK/RESIGNAL):

{{sql_finish}}

E5/T32 exprimă altă semantică: împrumutul P006 s-a încheiat real la 1 iulie; close+insert păstrează o credință curentă cu `valid_to` finit. E8 elimină credința curentă despre un fapt fals, păstrând istoricul TT. Imutabilitatea permite numai închiderea `tx_to` a unui rând deschis.

## 4. Dificultăți și încercări documentate

Q3 inițial a eșuat cu ERROR 1111: subinterogările corelate și agregarea frontierelor au fost combinate nevalid. Soluția executată separă candidații într-un helper ALGORITHM=TEMPTABLE și agregarea ulterioară. Regresiile au întâlnit ERROR 1267 din collation-uri diferite; runnerul aliniază numai sesiunea testelor vechi. Smoke-ul după instalarea view-urilor număra și coloanele acestora: s-a mutat înainte de 04. Logurile eșuate și cele PASS sunt păstrate în `evidence/historical_failures/` și `evidence/replay/`.

Ipoteza că indexul as-of va fi ales nu s-a confirmat pe aceste date (p. 5); indexul a fost restaurat în clonă. {{naive_demo_description}}

<!-- PAGE 3 -->
## Rezultate Part C — Q0, Q1, Q2 și Q3

Capturi CLI reale din `evidence/replay/results/`, cu CSV și parametri JSON. Q1/Q2: UTC_DATE=`{{evaluation_date}}`. {{run_description}}; comparațiile folosesc expected independent, iar parametrii sunt restaurați.

### Q0 — integritate și rollback

`SELECT COUNT(*) FROM v_integrity_violations` → 0 final. Diagnosticele negative reale de mai jos probează I1 (overlap), I3 (doi titulari), I2 (gol la părinte); după ROLLBACK → 0. I2 acceptă acoperirea prin părinți adiacenți. Gărzile/snapshot-urile probează I4 separat.

{{q0}}

### Q1 — fapte VT astăzi și curente TT pentru P006

`SELECT player_code,club_code,agreement_kind,salary_eur FROM v_q1_current_contracts ORDER BY club_code,valid_from` (subject rezolvat prin P006):

{{q1}}

### Q2 — mandat coalescat al CL04, as-known-now

`SELECT * FROM v_q2_coach_tenures` (CL04) → H05/Sorin Dima, `[2025-07-01,∞)`, `tenure_days=NULL`, `elapsed_days={{elapsed_days}}`: durata observată până la UTC_DATE. DISTINCT nu unește fragmentele adiacente.

### Q3 — toate 33 componente / 31 evenimente, proiecție compactă

`SELECT event_ref,fact_family,subject_code,event_codes,effective_date,delay_days,old_values,new_values FROM v_q3_event_audit ORDER BY tx_time,fact_family,subject_code`. Proiecție a tuturor componentelor: valori distincte vechi/noi și frontiera efectivă; intervalele/prefixele și TT complet rămân în `Q3_all_events.csv`. C=contract (club:EUR), B=buget EUR, H=rol (titular); `.00` omis, „—”=fără veche credință închisă; 25/26=2025/2026. Δ=DATEDIFF(data TT, data efectivă), negativ pentru E2.

{{q3}}

T19: H01 `[2025-07-01,2026-03-01)` / H02 `[2026-03-01,∞)` → H01 `[2025-07-01,2026-03-03)` / H02 `[2026-03-03,∞)`. T34/T35 modifică buget și salariu în același tx_id. Etichetele suprapuse: 13 E2, 18 E3, 5 E4.

<!-- PAGE 4 -->
## Rezultate Part C — Q4, Q5, Q6 și Q8

### Q5 — toate cele 77 fapte contractuale la un moment TT

`known_at='2026-09-21 12:00:00.000000'` UTC. `SELECT player_code,club_code,agreement_kind,salary_eur,valid_from,valid_to FROM v_q5_contracts_as_known ORDER BY player_code,club_code,valid_from`. Trei blocuri, toate 77 rânduri ale proiecției; TT/ID-urile repetitive sunt omise. P=PERMANENT, L=LOAN; EUR fără `.00`; datele VT sunt AA-LL-ZZ (25=2025,26=2026), capăt exclusiv, ∞=9999-12-31. CSV-ul integral `Q5_final.csv` include toate coloanele. Se filtrează numai TT: inclusiv fapte VT finite și viitoare, fără valid_at sau subiect.

{{q5}}

### Q4 — overlap versus containment, sezonul 2025/2026

Proiecție/extras din `SELECT player_code,club_code,at_some_point,throughout FROM v_q4_period_relationships`, cu `[2025-07-01,2026-07-01)`. P018–CL02 → `(1,1)`; P001–CL06 → `(1,0)`. „throughout” privește un fapt individual, nu reuniunea salariilor. Împrumutul P006–CL02 `[2026-06-01,2026-07-01)` față de exact aceeași perioadă → `(1,1)`; perioada care doar atinge capătul la 1 iulie → `(0,0)`. Ieșirile complete: `Q4_season1.csv`, `Q4_exact_loan.csv`, `Q4_touch_loan.csv`.

### Q6 — CL01, VT 2026-03-02, cele trei perspective UTC

`SELECT subject_code,subject_name FROM v_q6_bitemporal_point WHERE fact_kind='HEAD_COACH'`:

{{q6}}

Frontiere TT reale, capturi înainte/exact/după cu ±1µs: T18 la 10 martie 14:00 → H01/H02/H02; T19 la 15 martie 11:00 → H02/H01/H01. La momentul exact se selectează numai noua credință. Parametrii compleți sunt în `Q6_T18_*.json`, `Q6_T19_*.json`.

### Q8 — toate cele patru goluri între perioade ale aceleiași perechi

`SELECT player_code,club_code,gap_from,gap_to,gap_days FROM v_q8_relationship_gaps ORDER BY player_code,club_code,gap_from`. Coalescing proiectează relația fără split-uri salariale; LAG identifică numai goluri strict pozitive.

{{q8}}

<!-- PAGE 5 -->
## Q7, comparația EXPLAIN și concluzii tehnice

### Q7 — întreaga matrice 12 luni × 6 cluburi (72 valori)

`SELECT month_start,club_code,relationship_count FROM v_q7_monthly_relationships ORDER BY month_start,club_code`, pentru `[2025-07-01,2026-07-01)`, TT curent. Pivot integral din `Q7_season1.csv`: DISTINCT contract_id cu overlap în lună intersectată cu perioada cerută, fără dublări salariale. Calendarul recursiv × cluburi și LEFT JOIN păstrează zero: CL06 în iulie 2025.

{{q7}}

### Part A — cele două planuri reale Q6/CONTRACT

CL03, VT `2026-05-05`, TT `2026-05-11 12:00:00` UTC, aceeași clonă/98 versiuni. `SELECT * FROM v_q6_bitemporal_point WHERE fact_kind='CONTRACT' ORDER BY subject_code,valid_from,version_id`; index `ix_contract_version_asof(contract_id,tx_to,valid_from)`.

{{explain}}

Toate 7 rânduri/plan, proiecție type/key/rows/Extra: d2=`<derived2>`, PK=PRIMARY, CL=ix_contract_club, FK=ix_p3_contract_fk_support; W=Using where, F=Using filesort, I=Impossible WHERE, „—”=Extra gol. n=rows ESTIMATE, nu măsurate. Cu as-of: v=ALL/98; fără: a=ref/14, v=ref/1. Rezultate egale, as-of restaurat, suport FK eliminat în clonă; principala intactă. Experiment anterior: `evidence/explain/`, planuri integrale cu toate coloanele. Datasetul mic nu dovedește accelerare; fără benchmark de timp.

## 5. Concluzii — ce ajută motorul nativ

Course1 pp. 29–37: VT, SYSTEM_TIME și chei temporale; pp. 39–42: concurență, indexare, MVCC. Oracle Temporal Validity exprimă VT; Flashback Query recuperează TT din undo; Flashback Data Archive păstrează istoric conform retenției. I1/I3 (fără overlap pe cheia business) și I2 (acoperire prin uniunea VT a clubului) cer reguli suplimentare. Undo nu garantează singur I4 pe termen nelimitat [R1].

SQL Server system-versioned tables stampilează TT la începutul tranzacției UTC, păstrează istoria și interzic scrierea directă a SYSTEM_TIME/istoriei cât versionarea este activă: ajută I4/Q5, nu VT/I1–I3. Nu echivalează automat cu replay-ul backdated [R2].

PostgreSQL 18: range/multirange, `WITHOUT OVERLAPS`, FK cu `PERIOD`. Pe VT al credințelor curente, cheia business temporală ajută I1, role_id unic per club ajută I3; FK temporal spre existența clubului poate impune I2 prin uniunea perioadelor. FK simplu spre ancoră nu impune I2. TT/I4 cer protocol, trigger-e sau extensie. Assignment p. 6 anticipează `FOR PORTION OF` în 19; documentația 19 consultată se declară development, UPDATE nu confirmă clauza. Nu o tratăm ca stabilă/testată [R3–R4].

MariaDB 11.x: VT, WITHOUT OVERLAPS, SYSTEM VERSIONING (Course1 pp. 31/37; Assignment p. 6). Ar reduce gestiunea manuală a segmentelor/TT, fără a garanta toate regulile de business sau echivalența replay-ului. Core A–D este manual; A1/A2 neimplementate. MVCC, Flashback și istoricul explicit sunt distincte. Reconstrucția 01→05 verificată; GUI DBeaver/restore nativ netestate.

{{references}}
