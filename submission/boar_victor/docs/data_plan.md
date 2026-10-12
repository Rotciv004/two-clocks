# Planul datelor — Etapa 2

**Execuție: PASS.** Așteptările de mai jos au fost comparate cu SQL în două baze noi și în baza principală. CSV conține tx_id reale. Dovezi: [rezumat](../verification/phase2_summary.md). Surse: cerința utilizatorului, [Assignment1](references/Assignment1.txt), [planul autorat cu 38 de evenimente](timeline_plan.json), [generatorul protocolului](../scripts/build_phase2.py) și [rezultatele așteptate](expected_results.json). Schema Etapei 1 nu se modifică; bonusul A1 nu este implementat.

## Populație și încărcare inițială

T01/E1 aparține exclusiv `02_data.sql`; T02–T38 aparțin `03_timeline.sql`, în ordine TT strict crescătoare. SQL-ul este materializat și standalone: executarea 01 → 02 → 03 nu necesită Python. Generatorul este instrument de autorare, iar evenimentele sunt proiectate explicit.

Toate persoanele și cluburile sunt fictive. P001–P060 au numele „Jucător Fictiv NNN”, data nașterii 1995-01-01 + 37×(n−1) zile și salariul inițial 1000+10×n EUR. P001–P012 aparțin CL01, P013–P024 CL02, P025–P036 CL03, P037–P048 CL04, P049–P060 CL05; CL06 nu are contracte inițiale. Toate cele 60 de contracte inițiale sunt PERMANENT, din 2025-07-01 până la santinelă.

| Club | Nume | Buget inițial EUR | Titular inițial |
|---|---|---:|---|
| CL01 | FC Someș | 1000000 | H01 Andrei Ionescu |
| CL02 | FC Ardeal | 1100000 | H03 Radu Marin |
| CL03 | FC Mureș | 1200000 | H04 Vlad Stan |
| CL04 | FC Apuseni | 1300000 | H05 Sorin Dima |
| CL05 | FC Criș | 1400000 | H06 Dan Rusu |
| CL06 | FC Târnava | 1500000 | H07 Paul Muntean |

H02 este Mihai Popescu, H08 Alex Matei; H01–H08 au datele nașterii 1970-01-01 … 1977-01-01. CL04 are două angajamente adiacente ale aceluiași H05: [2025-07-01,2026-07-01) și [2026-07-01,9999-12-31). Acestea pregătesc coalescing pentru Q2 și nu reprezintă schimbarea titularului.

Sezoane: 2025/2026 [2025-07-01,2026-07-01), 2026/2027 [2026-07-01,2027-07-01). Datele acoperă peste 12 luni VT; TT planificat este 2025-07-01 09:00:00.000000 … 2026-09-20 10:00:00.000000 UTC. VT este DATE, TT DATETIME(6) UTC; intervalele sunt [from,to).

## Volume așteptate

| Tabel / măsură | După T01 | După T38 |
|---|---:|---:|
| player | 60 | 60 |
| coach | 8 | 8 |
| club | 6 | 6 |
| season | 2 | 2 |
| contract | 60 | 69 |
| head_coach_role | 6 | 6 |
| tx_registry | 1 | 38 |
| tx_event_tag | 1 | 53 |
| query_params | 1 | 1 |
| club_version, total | 6 | 18 |
| contract_version, total | 60 | 98 |
| head_coach_role_version, total | 7 | 15 |
| Toate versiunile | 73 | 131 |
| club_version, TT curent | 6 | 12 |
| contract_version, TT curent | 60 | 77 |
| head_coach_role_version, TT curent | 7 | 10 |
| Toate versiunile, TT curent | 73 | 99 |
| Ancore contract cu fapte TT curente | 60 | 68 |

Final: 32 versiuni TT închise (6 club, 21 contract, 5 rol). Cele 77 de fapte contractuale TT curente includ istoricul VT cunoscut acum; nu sunt 77 de relații active simultan. Sunt așteptate 58 de relații active la VT 2026-09-21 și 59 la VT 2026-10-15, ambele văzute la TT 2026-09-21 12:00:00.000000. Ancora P060–CL06 rămâne după retractare, fără fapt TT curent.

| Etichetă | Minim | Așteptat | Evenimente |
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

Etichetele nu sunt exclusive: 53 de asocieri la 38 de tranzacții logice. E9 numără două decizii explicite T34/T35, fiecare schimbând buget și salariu cu același `tx_id` și `v_time`; încărcarea inițială nu este numărată suplimentar ca E9.

## Semantica evenimentelor și CSV

[timeline.csv](timeline.csv) are exact un rând per T01–T38. `event_ref` este identificatorul stabil al planului; `tx_id` este rezolvat din registrul principal, nu dedus din numărul Tnn. `execution_status=verified_main`. `tx_time_utc` este TT planificat, nu dovadă de commit. `event_tags` este lista separată prin `;`; `primary_operation` păstrează operația din plan. Codurile și `business_key` identifică ancorele fără presupuneri despre AUTO_INCREMENT.

`effective_date` este data semantică a schimbării, preluată din `effective_from` al planului. Pentru E5 aceasta este noul sfârșit valid, nu începutul versiunii de înlocuire. `effective_to` păstrează sfârșitul explicit al planului; pentru T25 îl completează din intervalul afirmației T21 retractate, 2026-05-01; un câmp gol nu trebuie interpretat automat ca santinelă. `delay_days=DATE(tx_time_utc)−effective_date`, în zile calendaristice: negativ pentru E2, cel puțin 7 pentru E3. `description`/`reason` explică motivul fictiv al tranzacției.

`old_value`/`new_value` se referă la operația principală: salariu pentru transfer/salary/salary_correction, buget pentru budget/multi, cod antrenor pentru role, data demiterii pentru role_correction, vechiul/noul valid_to pentru end. Pentru inserare lipsește valoarea veche. La T25, valoarea veche identifică afirmația LOAN [2026-04-01,2026-05-01), salariu 600 EUR, iar valoarea nouă este `retract; no replacement`, fără versiune de înlocuire. Pentru T10–T14, old/new sunt 9999-12-31 → data încetării; pentru T32 sunt 2026-09-01 → 2026-07-01. Câmpul brut `old` al planului pentru operația end este salariul și nu se copiază ca old_value al încetării. La E9 operația principală numerică este bugetul, iar `components` este JSON cu ambele tabele, chei, atribute și valori old/new; pentru celelalte evenimente este `[]`.

E3 se măsoară față de data efectivă a evenimentului: T13 folosește încetarea 2026-01-01, deși noua versiune păstrează valid_from=2025-07-01. T19 folosește data corectată 2026-03-03 (12 zile); corecțiile salariale folosesc începutul segmentului corectat. Cele cinci transferuri T02/T03/T04/T06/T07 au întârzieri 10/16/24/45/54 zile și satisfac independent minimul E3.

La E2, close + insert produce un prefix cu vechea valoare și un sufix viitor. Prefixul păstrat nu reprezintă un nou eveniment întârziat. Q3 va clasifica evenimentele folosind metadatele planului (event_ref, etichete, effective_date, operație, old/new și components), corelate cu registrul real și versiunile, nu fiecare rând inserat ca eveniment distinct. Aceste metadate sunt externe; nu se adaugă tabele sau coloane schemei. Implementarea Q3 rămâne planificată.

Fereastra de transfer este o convenție fictivă a scenariului, închisă la sfârșitul zilei 2025-08-31; T02, efectiv 2025-08-31, este înregistrat abia la 2025-09-10. Nu este o regulă sportivă reală. T32 scurtează real împrumutul P006 la 2026-07-01 (E5); T19 corectează data demiterii (E4). Împrumuturile P006/P007/P008 păstrează contractele de origine, iar unicitatea temporală se aplică perechii player–club.

## Protocol standalone și atomicitate

02/03 utilizează blocuri anonime `BEGIN NOT ATOMIC`, fără proceduri persistente sau DDL de schemă. Atomicitatea fiecărui eveniment vine din `START TRANSACTION`/`COMMIT`. Handlerul `EXIT HANDLER FOR SQLEXCEPTION` citește diagnosticul, execută ROLLBACK, golește @sim_now/@write_tx_id, eliberează lockul deținut, raportează evenimentul eșuat/ultimul comis și execută RESIGNAL. Clientul trebuie să se oprească la eroare, fără `--force`. Evenimentele deja comise rămân comise; nu există rollback global sau reluare automată.

`GET_LOCK(CONCAT(DATABASE(),':phase2_replay'),0)` serializează replay-urile cooperante în namespace-ul bazei; lockul este eliberat explicit și la succes. Blocarea ancorelor existente se face prin cursoare `SELECT … ORDER BY PK FOR UPDATE`, în ordinea comună club → player → coach → contract → head_coach_role. Sunt blocate toate ancorele existente, inclusiv părinții relevanți; la E1 tabelele sunt goale, iar lockul nominal serializează încărcările cooperante. Protocolul nu înlocuiește respectarea aceleiași discipline de către alți writeri și nu constituie un test de concurență executat.

În fiecare eveniment, după blocări și verificarea prefixului, se setează @sim_now și se capturează o singură dată timpul în variabila locală `v_time=fn_effective_time()`. Acest timp efectiv al funcției este folosit în registru, la închideri și la inserări; se păstrează verificarea ceasului din schema existentă. ID-ul real se citește prin LAST_INSERT_ID(). T01 cere domeniul/registrul goale și query_params singleton; fiecare Tnn ulterior cere exact prefixul anterior și ordine TT strictă.

Tabelele temporare `p2_before_*` sunt create înaintea tranzacțiilor. Înaintea fiecărui eveniment se copiază toate versiunile în ele. Aserțiunile I4 compară imaginile înainte/după: fără dispariții sau schimbări de business, perioade VT, tx_from ori tx_id; numai tx_to deschis poate fi închis la v_time. Istoricul deja închis rămâne identic. Se verifică și legătura cu timpul registrului. Q0 trebuie să întoarcă zero încălcări I1–I3 înainte de COMMIT. Q0 singur nu probează I4. Mesajul PASS emis înainte de COMMIT nu dovedește commit; se urmăresc confirmarea `committed_event`, codul de ieșire și auditul final. Aceste verificări au trecut după fiecare T01–T38.

## Rezultate demonstrative așteptate și pași următori

Pentru CL01, VT 2026-03-02: înainte de T18 → H01; de la T18 inclusiv până la T19 exclusiv → H02; de la T19 inclusiv → H01. La VT 2026-03-03 după corecție titularul este H02. Cele cinci versiuni ale rolului CL01 păstrează toate cele trei perspective A → B → A.

Pauze Q8 așteptate: P013–CL02 [2025-12-01,2026-02-01), 62 zile; P014–CL02 [2025-12-15,2026-03-01), 76; P015–CL02 [2025-12-20,2026-03-10), 80; P006–CL02 [2026-07-01,2026-10-01), 92. CL04 se coalescează la un singur mandat H05. CL06 există în iulie 2025 cu zero contracte (Q7). P018–CL02 acoperă integral ambele sezoane, inclusiv prin uniunea versiunilor adiacente ale clubului (I2); P001–CL06 doar intersectează primul sezon (Q4).

T25 retrage doar afirmația T21 pentru intervalul [2026-04-01,2026-05-01), fără înlocuitor; T26 corectează salariul P025 1450→1455 în sufixul din mai, păstrând prefixul 1250. T33 corectează P027 1490→1495 din iulie. Bugetul CL06 rămâne 1500000 la 2026-10-15 și devine 1650000 la 2026-11-01. Detaliile și rezultatele literale complete sunt în [expected_results.json](expected_results.json), fără rezultate DB presupuse.

Parametrii finali planificați: params_id=1, valid_at=2026-03-02, known_at=2026-03-16 12:00:00.000000 UTC, period_start=2025-07-01, period_end=2026-07-01, subject_id rezolvat după codul CL01. Q1–Q8, `04_views.sql`, `05_tests.sql`, EXPLAIN și raportul rămân planificate. Comenzile CLI și story log-ul complet sunt în [README](../README.md).

## Orchestrare și replay — execuție verificată

Comenzile exacte sunt în secțiunea CLI Etapa 2 din README. `verify_dataset.sh` apelează `phase2_runner.py verify`: două baze noi, fiecare cu 01→02→03, a doua cu teste Etapa 1 înainte de 02 pentru ID-uri surrogate diferite; comparație după coduri și perioade, audit și verificarea refuzului duplicatelor. Mecanismul de replay este executarea scripturilor de două ori în baze separate. Exportul nativ nu are restaurarea testată (`restore_tested=false`).

`populate_main.sh` apelează `phase2_runner.py main`: cere checksum-urile fișierelor unei verificări reușite, compară schema fingerprint, salvează backup dump înainte de populare și execută direct 02/03 plus audit doar în citire și comparație normalizată. Nu recreează schema principală. La repetare, datasetul complet este comparat și auditat; dacă este identic, răspunsul este `ALREADY POPULATED`, fără DML. Datasetul parțial sau necunoscut este păstrat, iar popularea refuzată. Popularea și auditul au trecut; manifestele consemnează execuțiile reale.


Starea finală de predare este în README și requirements_matrix.md. Formulările istorice „planificat” descriu etapele anterioare. PDF-urile cursului sunt consultate în proiectul autorului; pachetul nu redistribuie materialul de curs.


Starea finală de predare este în README și requirements_matrix.md. Formulările istorice „planificat” descriu etapele anterioare. PDF-urile cursului sunt consultate în proiectul autorului; pachetul nu redistribuie materialul de curs.


Starea finală de predare este în README și requirements_matrix.md. Formulările istorice „planificat” descriu etapele anterioare. PDF-urile cursului sunt consultate în proiectul autorului; pachetul nu redistribuie materialul de curs.
