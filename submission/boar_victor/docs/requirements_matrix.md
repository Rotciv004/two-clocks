# Matricea cerințelor — Two Clocks

## Stare de predare / Etapa 4

| Parte | Stare efectivă | Dovadă |
|---|---|---|
| A | Verificată anterior; 01 neschimbat, index as-of prezent în definițiile verificate | source_audit.json; summary.md; logurile EXPLAIN |
| B | Verificată anterior și în replay-ul NOU al pachetului; 02/03 și expected neschimbate; 67 + 483 aserțiuni trecute | phase2_summary.md; replay_package_1/manifest.json și logurile dataset/timeline |
| C | Verificată anterior și în replay-ul NOU; 04/05 și oracle neschimbate; 52 + 4 verificări; capturi noi în raport | phase3_summary.md; CSV/JSON în evidence/replay/results; report_layout.json |
| D | Raport de 5 pagini A4, diagramă vectorială/PNG, surse, dovezi și arhivă extrase/verificate. Un replay NOU al pachetului este PASS; fingerprint, structură și parametri ai principalei neschimbați | phase4_summary.md; pdf_checks.json; diagram_audit.json; archive_validation.json; replay_package_1/manifest.json |
| Bonus A1 | Neimplementat: scripturile core scriu TT direct; gărzile singure nu satisfac bonusul | 02_data.sql / 03_timeline.sql |
| Bonus A2 | Neimplementat: comparația teoretică din raport nu este o reimplementare nativă | report.pdf |

Secțiunile care urmează păstrează istoricul etapelor anterioare. Formulările „planificat” sunt istorice; starea de mai sus este cea curentă. Core A–D este pregătit pentru predare. GUI DBeaver și restaurarea nativă a dumpurilor rămân netestate.

## Interpretarea statusului

„Verificat” în secțiunile Etapei 1 indică probe istorice executate pe MariaDB 11.8.8; dovezile sunt în [verification/summary.md](../verification/summary.md). „Documentat” indică explicații și protocol. „Planificat” înseamnă etapă viitoare, neimplementată. Concurența este tratată prin protocolul documentat; nu a fost efectuat un test de stres cu sesiuni paralele.

Surse: cererea inițială a utilizatorului, [Assignment1.pdf](references/Assignment1.pdf), [Course1.pdf](references/Course1.pdf), extrasele `docs/references/Assignment1.txt` și `docs/references/Course1.txt`. Cerințele de mai jos păstrează domeniul și schema exactă din prompt.

## Etapa structurală și documentația

| ID | Cerință | Obiect / dovadă cerută | Status |
|---|---|---|---|
| D1 | Dicționar complet, model temporal și justificări | schema_design.md | Documentat |
| D2 | 6 ancore non-temporal, 3 versiuni bitemporale, 3 auxiliare tehnice | Dicționar și diagramă | Documentat |
| D3 | PK/FK, crow's-foot, separarea categoriilor, sursă și PNG | er_diagram.dot / er_diagram.png | Diagramă creată; randare Graphviz separată de testele SQL |
| A1 | Exact cele 12 tabele; minimum 5 entități de domeniu | 01_schema.sql; INFORMATION_SCHEMA | Verificat |
| A2 | BIGINT UNSIGNED, AUTO_INCREMENT, NOT NULL, InnoDB, utf8mb4 | DDL, SHOW CREATE TABLE | Verificat |
| A3 | Unicitate coduri, pereche jucător–club, rol per club | UNIQUE și teste negative | Verificat |
| A4 | FK către ancore/registru, RESTRICT, fără cascade | DDL și probe FK | Verificat |
| A5 | Date VT; DATETIME(6) UTC pentru TT; santinele exacte | DDL / metadate și probe de limite | Verificat |
| A6 | CHECK VT/TT strict crescătoare; sume nenegative; tip PERMANENT/LOAN | Constrângeri și teste negative | Verificat |
| A7 | Un tx_id și moment comun; tx_time neunic | tx_registry, trigger-e, fixture E9 | Verificat |
| A8 | Etichete E1–E9, multiple per schimbare, fără duplicate | tx_event_tag, PK compus | Verificat |
| A9 | query_params: cel mult un rând prin PK/CHECK și existență asigurată de script | Rândul inițial exact; test actualizare / al doilea rând | Verificat |
| A10 | subject_id interpretat per view, fără FK arbitrar | Dicționar; viitoarele view-uri | Documentat; view-uri planificate |
| A11 | Cele trei indexuri as-of și suport FK fără duplicate inutile | Catalog indexuri; SHOW INDEX | Verificat |
| A12 | Imutabilitatea identităților contract/rol | Gărzi UPDATE pentru PK și referințe | Verificat |
| W1 | Numai închiderea tx_to pe versiune deschisă; niciun DELETE | Gărzi pe toate coloanele și probe negative | Verificat |
| W2 | INSERT deschis, tx_from egal cu registrul, istoric/registru/metadate protejate | Gărzi și probe de rescriere | Verificat |
| W3 | @sim_now invalid/viitor respins; VT viitor acceptat; moment UTC capturat o dată | Teste de ceas simulat și precizie | Verificat |
| W4 | Close + insert atomic; E3/E4/E5/E8/E9; ancore blocate în ordine | docs/write_protocol.md și teste de rollback | Exemple și rollback verificate; concurență documentată |
| I1 | Fără suprapuneri VT pentru aceeași cheie în TT curent | v_integrity_violations | Verificat |
| I2 | Copil acoperit de uniunea intervalelor clubului | Q0: părinți adiacenți, suprapuși, pauze, lipsă totală | Verificat |
| I3 | Un singur titular la orice dată pentru club | Q0: roluri suprapuse | Verificat |
| I4 | Istoric imutabil; fără TT efectiv viitor | Gărzi și probe negative; Q0 singur nu dovedește I4 | Verificat |
| Q0 | Ieșire consistentă, fără query_params, zero pe fixture valid | invariant_code, source_table, business_key, version_id, conflicting_version_id, details | Verificat |
| S1 | Creare nedistructivă separată de recrearea obiectelor | 00_create_database.sql / 01_schema.sql fără USE fix | Verificat |
| S2 | Execuție de la zero și rerulare într-o bază nouă separată | scripts/verify_schema.sh; two_clocks_cabd_verify_<sufix_unic> | Verificat |
| S3 | Export real cu view și trigger-e; fără rândul query_params | exports/schema_only.sql prin mariadb-dump | Verificat |
| S4 | Baza principală fără fixture-uri; date existente păstrate | Verificări înainte/după; backup dacă există date | Verificat |
| S5 | Versiuni efective, conexiune existentă, CLI/DBeaver, loguri | README.md și verification/summary.md | CLI verificat; GUI DBeaver documentat, netestat |

## Inventarul verificărilor obligatorii

Toate probele de mai jos sunt cerute în `tests/01_schema_smoke.sql`, orchestrat de `scripts/verify_schema.sh`. Status: **trecut pe serverul local**, conform logurilor finale. Gărzile rămân active; erorile așteptate sunt recunoscute după motiv, fără `--force`. Fixture-urile se izolează prin tranzacții/ROLLBACK; DDL se creează separat, deoarece poate produce commit implicit.

| Test din prompt | Probă cerută |
|---|---|
| 1 | Schema rulează pe o bază goală. |
| 2 | A doua execuție recreează obiectele fără eroare. |
| 3 | Exact trei versiuni bitemporale, tipuri, precizie, santinele și CHECK confirmate prin metadate. |
| 4 | Perioade VT nule/inversate și TT inversat respinse. |
| 5 | FK inexistent, salariu/buget negativ, agreement_kind invalid respinse. |
| 6 | Perioade adiacente acceptate; Q0 fără încălcări. |
| 7 | Suprapuneri VT curente detectate de I1. |
| 8 | La limita comună TT numai noua versiune este selectată. |
| 9 | I2 acceptă acoperirea prin doi părinți adiacenți; detectează pauza, depășirea și părintele absent; uniunea gestionează suprapunerile. |
| 10 | Doi titulari simultani ai aceluiași club sunt detectați de I3. |
| 11 | UPDATE business, UPDATE istoric închis, redeschidere, DELETE și reinterpretare ancore respinse. |
| 12 | tx_from diferit de registru și TT viitor respinse; @sim_now invalid respins; ceas absent tratat corect; VT viitor și intrare tardivă acceptate. |
| 13 | Schimbare pe două tabele, același tx_id/moment; eșec intermediar anulează totul. |
| 14 | Singleton actualizabil; al doilea rând și perioada de analiză invalidă respinse. |
| 15 | Q0 zero pe fixture valid și diagnostic explicativ pentru fiecare încălcare intenționată. |
| Caz demonstrativ | Exact cinci versiuni; valid_at 2026-03-02, known_at 5/12/16 martie 2026 la 12:00 UTC → Ionescu / Popescu / Ionescu; limite exclusive. |

## Volume finale — verificate

| Cerință | Prag / semantică | Livrabil viitor | Status |
|---|---|---|---|
| Jucători | Minimum 50 ancore | 02_data.sql + 03_timeline.sql | Verificat prin SQL |
| Antrenori | Minimum 5 ancore | 02_data.sql + 03_timeline.sql | Verificat prin SQL |
| Cluburi | Minimum 6 ancore | 02_data.sql + 03_timeline.sql | Verificat prin SQL |
| Relații curente TT | Minimum 60 fapte, inclusiv istoric VT cunoscut acum; nu toate active în aceeași zi | Date finale și verificări de numărare | Verificat prin SQL |
| Versiuni | Minimum 120 rânduri în total în cele trei tabele bitemporale | Date finale și verificări de numărare | Verificat prin SQL |
| Orizont | Minimum 12 luni VT | Date finale | Verificat prin SQL |
| Perioade numite | 2025/2026 [2025-07-01, 2026-07-01); 2026/2027 [2026-07-01, 2027-07-01) | season și date finale | Verificat prin SQL |

## Etapa 2 — livrabile și rezultate așteptate

Status Etapa 2: **PASS**. Valorile proiectate au fost confirmate prin SQL; dovezi în [rezumat](../verification/phase2_summary.md). [data_plan.md](data_plan.md) conține protocolul, populația, toate totalurile și interpretările; [timeline.csv](timeline.csv) conține 38 de rânduri cu tx_id reale din principală; [README](../README.md) conține story log-ul românesc complet. Schema Etapei 1 rămâne neschimbată.

| Cerință | Livrabil / rezultat așteptat | Status |
|---|---|---|
| Populație | 60 player, 8 coach, 6 club, 2 season, 69 contract, 6 roluri | Verificat prin SQL |
| Versiuni | 18 club + 98 contract + 15 rol = 131; inițial 73 | Verificat prin SQL |
| TT curent | 12 club + 77 contract + 10 rol = 99; 68 ancore contract reprezentate | Verificat prin SQL |
| Registru / parametri | 38 tranzacții, 53 etichete, 1 query_params | Verificat prin SQL |
| Replay | 02_data.sql T01; 03_timeline.sql T02–T38; standalone, fără Python runtime | Executat și verificat |
| Atomicitate / I4 / Q0 | Handler ROLLBACK/RESIGNAL, before snapshots temporare, verificări înainte de COMMIT | Executat și verificat |
| Concurență | GET_LOCK per bază; cursoare toate ancorele, PK în ordinea club/player/coach/contract/rol | Protocol executat; concurența între sesiuni nu a fost testată |
| Ceas | v_time local capturat o dată prin fn_effective_time; ID real LAST_INSERT_ID | Executat și verificat |
| Replay verificabil | phase2_runner.py verify: 01→02→03 de două ori în baze noi, ID-uri diferite și comparație normalizată; fără restore nativ testat | Executat și verificat |
| CLI sigur | phase2_runner.py main prin populate_main.sh: checksum, schema fingerprint, backup dump, direct 02/03 și audit doar în citire | Executat și verificat |
| Repetare main | Dataset complet identic: comparație + audit, ALREADY POPULATED fără DML; dataset parțial/necunoscut păstrat și refuzat | Executat și verificat |
| Schema / A1 | Fără schimbare de schemă; fără API persistent A1 | Delimitare documentată |
| Story log | 38 evenimente în română, dată efectivă, TT și motiv; CSV old/new și E9 components JSON | Documentat |

## Cronologia finală E1–E9 — așteptări, execuție verificată

| Eveniment | Minim | Așteptat | Referințe |
|---|---:|---:|---|
| E1 | 1 | 1 | T01 |
| E2 | 3 | 13 | T05, T08, T09, T15, T17, T22, T27, T31, T34, T35, T36, T37, T38 |
| E3 | 5 | 18 | T02, T03, T04, T06, T07, T13, T16, T18, T19, T20, T21, T23, T24, T26, T28, T29, T30, T33 |
| E4 | 3 | 5 | T19, T23, T24, T26, T33 |
| E5 | 5 | 6 | T10, T11, T12, T13, T14, T32 |
| E6 | 3 | 4 | T15, T17, T20, T38 |
| E7 | 3 | 3 | T16, T18, T36 |
| E8 | 1 | 1 | T25 |
| E9 | 2 | 2 | T34, T35 |

T02 demonstrează transferul înregistrat după fereastra fictivă; T32 scurtează împrumutul; T18/T19 corectează data demiterii. E7 schimbă titularul pe CL01/CL02/CL03 și pregătește răspunsurile H01 → H02 → H01 pentru aceeași dată VT. T34/T35 schimbă bugetul și salariul în aceeași tranzacție. E3 folosește data efectivă de încetare/corecție; prefixele E2 nu sunt intrări întârziate suplimentare. Q3 corelează registrul și versiunile reale; planul este oracle independent, fără extinderea schemei. Rezultatele detaliate rămân așteptări în [expected_results.json](expected_results.json).

## Interogări Part C și predare finală

| Cerință | Rezultat / dovadă viitoare | Status |
|---|---|---|
| Q0 în pachetul final | Recreat consecvent în 04_views.sql; zero pe datele finale și încălcare intenționată demonstrată în 05_tests.sql | Verificat Part C: zero și fixture-uri I1/I2/I3 cu rollback |
| Q1 | Contracte actuale ale jucătorului, VT astăzi și TT curent | Verificat Part C; vezi verification/phase3_summary.md |
| Q2 | Istoricul titularilor clubului, coalescing și durate | Verificat Part C; vezi verification/phase3_summary.md |
| Q3 | E2/E3/E4 clasificate, întârziere și valori vechi/noi | Verificat Part C; vezi verification/phase3_summary.md |
| Q4 | Fapte contractuale cândva în sezon (overlap) versus pe întregul sezon (containment) | Verificat Part C; vezi verification/phase3_summary.md |
| Q5 | Întreaga relație la known_at, fără filtru VT | Verificat Part C; vezi verification/phase3_summary.md |
| Q6 | Punct bitemporal, cele trei perspective; aceeași dată validă | Verificat Part C; vezi verification/phase3_summary.md |
| Q7 | Calendar lunar explicit și cluburi cu zero relații | Verificat Part C; vezi verification/phase3_summary.md |
| Q8 | Pauze per pereche, LAG/LEAD, toate revenirile E6 | Verificat Part C; vezi verification/phase3_summary.md |
| Ieșiri Q0–Q8 | CSV UTF-8 per scenariu + JSON parametri în verification/phase4/replay_package_1/results, distribuite în evidence/replay/results | Capturi noi; Q3/Q5/Q7 complete prin proiecții/pivot, Q4 extras explicit |
| EXPLAIN Q6 | Cu/fără index, pe date reprezentative; fără benchmark inventat | Verificat Part C; vezi verification/phase3_summary.md |
| Raport ≤ 5 pagini | Domeniu; decizii; SQL E3/E4/E8; dificultăți și încercări reale; comparație cu facilități native Oracle/SQL Server/PostgreSQL din curs; ieșiri și EXPLAIN | Final: 5 pagini A4, control automat și vizual pe toate paginile |
| Bonus A1 (+1) | API automat TT nu este implementat; gărzile core nu satisfac bonusul | Neimplementat, în afara acestei etape; fără fișier bonus fictiv |
| Bonus A2 (+1) | Varianta MariaDB temporal nativ și echivalențele nu sunt implementate | Neimplementat, în afara acestei etape; fără fișier bonus fictiv |
| Pachet final | README, 01–05 SQL, diagramă ER PNG/PDF/DOT, report.pdf, dependențe și dovezi complete | ZIP extras, manifest și identitate cu pachetul testat verificate |
| Rulare finală | Scripturile 01–05 în ordine de la zero, din pachet, în bază nouă | Un replay nou al pachetului PASS; demonstrația live la seminar urmează |
| Termen | Seminarul 3; nicio dată calendaristică dedusă | Planificat |
| Destinație predare | CABD Team/Assignment1/boar_victor, distinct de directorul local Two Clocks | Pregătit local; neîncărcat, fără mesaje/publicare |

Evaluarea din assignment: A 1,5p; B 2p; C 3p; D 1,5p; bonusuri A1/A2 câte 1p. Aceasta este maparea baremului, nu o notă obținută. Raportul nu va inventa încercări eșuate, rezultate SQL, planuri EXPLAIN sau măsurători. Nu se creează fișiere SQL goale pentru etapele viitoare.

## Dovezi Part C

- `04_views.sql`: nouă view-uri publice și helper-e; `05_tests.sql`: 52 scenarii pozitive independente, plus 4 verificări Q0 în mod negativ izolat (I1, I3, acoperire I2 prin adiacență, gol I2).
- `docs/query_expected_results.json`: rezultate literale/model independent. Matricea Q7 din prompt verificată separat în `verification/phase3/monthly_oracle_check.json`.
- Q3: 31 evenimente distincte / 33 componente, 13 E2 / 18 E3 / 5 E4, toate valorile și intervalele JSON vechi/noi comparate.
- Q6: trei perspective și frontiere VT/TT ±1µs, plus toate faptele contractuale ale punctelor demonstrative.
- Rerulare 04/05 fără replay-ul datelor; două reconstrucții cu ID-uri diferite și rezultate normalizate identice; restaurare parametri inclusiv după eroare și refuz explicit fixture-uri în principală.
- EXPLAIN pe view-ul real, cu/fără as-of, FK susținut prin index simplu; rezultate egale, index restaurat în clonă. Fără benchmark pretins.
- Statusul instalării principale, backupurile, fingerprinturile și căile exacte ale logurilor sunt consemnate în `verification/phase3_summary.md`.
