# Two Clocks — Etapele 1–4

Stare Etapa 4: raportul A4 de **5 pagini**, diagrama PDF/PNG și pachetul portabil sunt livrate. Replay-ul NOU 01→05 din propriile copii a trecut 52 scenarii pozitive, 4 verificări Q0, 67 cazuri dataset și 483 aserțiuni timeline. Principală, structură și query_params sunt identice înainte/după, prin metoda fingerprint originală. ZIP-ul este extras și verificat prin manifest; vezi `verification/phase4_summary.md`. Secțiunile Etapelor 1–3 de mai jos păstrează istoricul. A1/A2 sunt neimplementate; GUI DBeaver și restore nativ de dump sunt netestate.

Ligă fictivă de fotbal, CABD — Advanced Database Chapters and Cloud Databases. Modelul păstrează când un fapt era valabil (valid time, VT) și când baza îl considera adevărat (transaction time, TT). Întrebarea demonstrativă este cine antrena FC Someș la 2 martie 2026, văzut din trei momente ale cunoașterii.

Etapa 1 a livrat structura Part A, protecțiile istoricului, Q0, teste și documentație. Etapa 2 adaugă planul și SQL-ul pentru date/cronologie; **Etapa 2 este executată și verificată**. **Nu reprezintă întregul assignment terminat.** Starea executării și dovezile sunt în [verification/summary.md](verification/summary.md).

## Mediu și locație — istoric Etapa 1

- Director exact: `/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks/`.
- Baza logică principală: `two_clocks_cabd`; utf8mb4 / utf8mb4_unicode_ci, InnoDB.
- Verificat pe serverul existent `VictorPC`, socket `/var/lib/mysql/mysql.sock`: **11.8.8-MariaDB**, `CURRENT_USER() = root@localhost`.
- Fedora 44 KDE; pachete: mariadb-server 11.8.8-3.fc44, DBeaver Community 26.2.1, Plasma 6.7.5.
- Autentificarea efectiv folosită: `pkexec` și autentificarea locală existentă a MariaDB. Conexiunea fără parolă a utilizatorului RotcivRaob a fost respinsă; `sudo -n` a cerut autentificare. Nu s-au creat conturi/parole și nu s-a modificat autentificarea.
- Inspecția a găsit directorul gol, fără repository Git și fără AGENTS.md aplicabil. Baza principală nu exista. Nu s-a reinstalat nimic și nu s-a mutat datadir-ul.

Fișierele SQL, documentația și exportul sunt în directorul proiectului. Datele interne ale serverului rămân în stocarea administrată de MariaDB. Sandboxul uneltelor a necesitat escaladare pentru socket; serverul identificat este cel local existent, nu un MariaDB substitut instalat într-un container.

## Fișiere și ordinea de lucru

| Fișier | Rol |
|---|---|
| `00_create_database.sql` | Creează nedistructiv baza dedicată; nu selectează și nu golește baza |
| `01_schema.sql` | **Recreează obiectele și șterge datele lor** în baza selectată de client; tabele, indexuri, funcție de ceas, trigger-e, Q0, parametru inițial |
| `scripts/install_main.sh` | Instalare inițială protejată: refuză orice bază principală cu obiecte existente; produce export real |
| `scripts/verify_schema.sh` | Creează un nume nou de test, rulează schema de două ori, ambele suite, păstrează baza și logurile; exit nenul la eșec |
| `tests/01_schema_smoke.sql` | Aserțiuni și erori așteptate, metadate, I1–I4, cinci versiuni, rollback atomic |
| `tests/02_write_examples.sql` | Exemple executabile independente E3/E4/E5/E8/E9, cu verificări și ROLLBACK |
| `docs/schema_design.md` | Dicționar complet, cardinalități, perioade, indexuri, semantica Q1–Q8 |
| `docs/write_protocol.md` | Protocol atomic, blocări concurente și SQL complet identic cu exemplele testate |
| `docs/requirements_matrix.md` | Maparea cerințelor, dovezi și cerințele viitoare |
| `docs/references/` | PDF-uri nemodificate, extrase text, proveniență și SHA-256 |
| `er_diagram.dot`, `er_diagram.png` | Sursa Graphviz și diagrama randată, cu PK/FK și crow's-foot |
| `exports/schema_only.sql` | Export structural real prin mariadb-dump, inclusiv view, funcție și trigger-e |
| `verification/` | Versiuni, loguri complete, rezultate și rezumat |
| `scripts/build_schema.py`, `scripts/build_tests.py` | Generatoare locale pentru SQL; nu sunt necesare rulării livrabilelor SQL |

02_data.sql și 03_timeline.sql sunt livrabilele Etapei 2, executate și verificate; 04/05 sunt livrate în Etapa 3. Etapa 4 a finalizat raportul și pachetul verificat; bonusurile A1/A2 rămân neimplementate. În Etapa 1 ordinea recomandată era **verificare separată → instalare principală inițială → inspecție/export**. DDL produce commit implicit: nu se anulează prin ROLLBACK.

## Comenzi CLI Etapa 1 — istoric și referință

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
```

Verificare completă, repetabilă. **Recreează obiecte numai într-o bază de test nouă**, niciodată în baza principală:

```bash
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/verify_schema.sh"
```

Scriptul afișează numele bazei `two_clocks_cabd_verify_<sufix_unic>` și directorul logurilor. Nu șterge baze preexistente. Dacă folosești deja un fișier privat de conexiune MariaDB, alternativa este `bash "$CABD_PROJECT_ROOT/scripts/verify_schema.sh" --defaults-extra-file=/cale/catre/configuratia_existenta.cnf`. Nu introduce valoarea parolei în comandă și nu salva acreditări în proiect. Sunt necesare CREATE/DROP/ALTER/INDEX/REFERENCES, DML, CREATE VIEW/SHOW VIEW, TRIGGER, CREATE ROUTINE/ALTER ROUTINE/EXECUTE și CREATE TEMPORARY TABLES în bazele proiectului; autentificarea locală administrativă a fost suficientă, fără granturi noi.

Prima instalare, **doar dacă baza nu are obiecte**:

```bash
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/install_main.sh"
```

Acum, dacă baza este deja instalată, scriptul se oprește cu exit 2 și o păstrează. `00_create_database.sql` separat este nedistructiv:

```bash
pkexec /usr/bin/mariadb < "$CABD_PROJECT_ROOT/00_create_database.sql"
```

Inspecție, fără recreare:

```bash
pkexec /usr/bin/mariadb --database=two_clocks_cabd --batch \
  -e 'SELECT VERSION(), DATABASE(); SHOW FULL TABLES; SELECT * FROM query_params; SELECT * FROM v_integrity_violations;'
```

**Comandă distructivă asupra obiectelor selectate:** `mariadb --database=NUME_BAZA < "$CABD_PROJECT_ROOT/01_schema.sql"`. Folosește-o numai pentru o bază de test cunoscută sau o resetare aprobată explicit. `01_schema.sql` nu conține USE fix; runnerul verifică DATABASE() înainte de DDL. Nu rula această comandă asupra bazei principale populate. Pentru date existente, exportă întâi și proiectează o migrare; instalatorul nu presupune că numele bazei îi dovedește proveniența.

Export structural repetabil, fără modificări în bază:

```bash
pkexec /usr/bin/mariadb-dump --no-data --routines --triggers \
  --default-character-set=utf8mb4 two_clocks_cabd > "$CABD_PROJECT_ROOT/exports/schema_only.sql"
```

Exportul fără date **nu include rândul query_params**. Pentru o instalare utilizabilă preferă 00 + 01; la restaurarea exclusivă a dump-ului adaugă separat rândul tehnic exact din 01. Dump-ul păstrează DEFINER-ul contului local care a creat obiectele; restaurarea pe alt server trebuie să țină cont de conturi și permisiuni.

## DBeaver

1. Deschide conexiunea MariaDB locală deja configurată, folosind autentificarea salvată existentă. Nu modifica autentificarea root pentru JDBC. Conexiunea CLI prin socket nu implică automat autentificare root prin JDBC.
2. Refresh pe conexiune și selectează `two_clocks_cabd` ca schemă activă. În SQL Editor execută `SELECT VERSION(), CURRENT_USER(), DATABASE();` și confirmă schema.
3. Execută `SHOW FULL TABLES;`, `SELECT * FROM query_params;` și `SELECT * FROM v_integrity_violations;`. Deschide Tables, Views, Triggers și Procedures/Functions pentru structură.
4. Pentru teste folosește baza nouă al cărei nume este în logul runnerului. Schema se recreează doar acolo. Scripturile cu `DELIMITER` se rulează prin **Execute SQL Script / execuție nativă MariaDB**, cu delimitatorii procesați; nu selecta tot conținutul ca un singur statement JDBC. CLI-ul de mai sus este calea verificată efectiv.
5. Pentru o intervenție tranzacțională folosește manual commit și protocolul din docs. La eroare execută ROLLBACK. Nu comite fixture-urile: testele au propriile ROLLBACK.

Pașii DBeaver sunt documentați; nu este pretinsă o execuție automată a interfeței grafice sau testarea acreditărilor ei.

## Tabelele și cele două ceasuri

| Grup | Tabel | Rol |
|---|---|---|
| Domeniu netemporal | `player`, `coach` | Identități, cod, nume și data nașterii considerate fixe |
| Domeniu netemporal | `club` | Identitate stabilă; existența temporală rezultă din versiunile curente |
| Domeniu netemporal | `season` | Definiție fixă a unei perioade de analiză |
| Domeniu netemporal | `contract` | O singură ancoră pentru perechea player–club, inclusiv revenirile |
| Domeniu netemporal | `head_coach_role` | O singură poziție de antrenor principal per club |
| Bitemporal | `club_version` | Nume și buget EUR |
| Bitemporal | `contract_version` | PERMANENT/LOAN și salariu EUR |
| Bitemporal | `head_coach_role_version` | Titularul poziției |
| Tehnic | `tx_registry` | Un tx_id și un timestamp UTC per schimbare, autor și motiv |
| Tehnic | `tx_event_tag` | Etichete multiple E1–E9 per schimbare |
| Tehnic | `query_params` | Parametrii viitoarelor view-uri |

Sunt șase entități de domeniu și exact trei tabele bitemporale. Tabelele tehnice nu intră în minimul academic de entități.

VT are granularitate de o zi și santinela `9999-12-31`; TT are microsecunde, UTC și santinela `9999-12-31 23:59:59.999999`. Ambele intervale sunt [from,to). Predicatul de punct este `valid_from <= valid_at AND valid_at < valid_to AND tx_from <= known_at AND known_at < tx_to`. Scrierea este close + insert; E5 încheie realitatea cu un valid_to finit, E8 retrage credința fără înlocuitor. @sim_now invalid sau viitor este respins. `fn_effective_time()` validează/capturează ceasul, fără a fi API-ul bonus A1.

Q0 detectează I1/I2/I3, inclusiv acoperirea I2 prin uniunea perioadelor clubului. Gărzile și testele negative probează I4; Q0 nu dovedește singur istoricul imutabil. Trigger-ele nu sunt o barieră împotriva unui administrator care poate schimba DDL-ul. Concurența presupune protocolul comun de blocare, documentat, fără benchmark sau test de stres pretins.

`query_params` are inițial exact `(1, '2026-03-02', '2026-03-16 12:00:00.000000', '2025-07-01', '2026-07-01', 1)`. PK/CHECK permit **cel mult** un rând; scriptul asigură existența lui. `subject_id` înseamnă player_id sau club_id potrivit view-ului și nu are FK arbitrar. Valoarea 1 nu dovedește existența vreunei entități cu acel ID.

Sezoanele exemplului sunt 2025/2026 `[2025-07-01,2026-07-01)` și 2026/2027 `[2026-07-01,2027-07-01)`. Sunt convenții fictive. Încărcarea lor în `season` aparține 02_data.sql; la finalul verificării Etapei 1, baza principală păstra numai rândul tehnic query_params. Etapa 2 a populat și verificat baza principală; vezi verification/phase2_summary.md.

## Surse și ajustări academice

Documentele au fost citite integral, din:

- `.../CABD/CURS/Course1.pdf`, 44 pagini;
- `.../CABD/SEMINAR/Assignment1.pdf`, 7 pagini.

Pathurile absolute și hashurile sunt în [docs/references/sources.json](docs/references/sources.json). Copiile nemodificate se află alături. Exemplul minimal din Assignment este ilustrativ; aici se aplică modelul mai precis din prompt cu ancora contract separată. Formularea „three different answers” din checklist este interpretată conform exemplului academic A → B → A, fără a inventa trei nume distincte. Q4 va distinge atât punctul valid din sezon, cât și suprapunerea cu sezonul și acoperirea întregului sezon. Nu s-a inventat o încercare eșuată pentru raport.

Pentru detaliile MariaDB au fost consultate documentațiile oficiale [microsecunde](https://mariadb.com/docs/server/reference/sql-functions/date-time-functions/microseconds-in-mariadb), [funcții window](https://mariadb.com/docs/server/reference/sql-functions/special-functions/window-functions/window-functions-overview), [CREATE VIEW](https://mariadb.com/docs/server/server-usage/views/create-view) și [trigger-e](https://mariadb.com/docs/server/server-usage/triggers-events/triggers/trigger-overview). Sintaxa livrată este verificată pe serverul local; descrierea modelului academic provine din PDF-uri și cerință.

## Etapa 2 — date și cronologie, execuție verificată

[Planul complet](docs/data_plan.md), [timeline.csv](docs/timeline.csv), [planul autorat](docs/timeline_plan.json) și [rezultatele așteptate](docs/expected_results.json) descriu 38 de evenimente: T01 în `02_data.sql`, T02–T38 în `03_timeline.sql`. Sunt așteptate 60 jucători, 8 antrenori, 6 cluburi, 2 sezoane, 69 ancore contract, 131 versiuni totale și 77 fapte contractuale curente în TT. Aceste cifre au fost confirmate prin SQL în cele două replay-uri și în principală.

Etichete așteptate: E1=1, E2=13, E3=18, E4=5, E5=6, E6=4, E7=3, E8=1, E9=2 (53 asocieri). CSV conține `tx_id` reale, rezolvate după auditul principalei și JSON `components` pentru ambele modificări E9. Rezultatele și linkurile Etapei 1 de mai sus sunt istorice și nu certifică datasetul Etapei 2.

### CLI Etapa 2

Comenzi exacte pentru runner-ele existente; execuție **PASS**. Wrapper-ele apelează `scripts/phase2_runner.py` în modul `verify`, respectiv `main`:

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/verify_dataset.sh"
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/populate_main.sh"
```

Se rulează întâi `verify_dataset.sh`, apoi, numai după succesul verificării, `populate_main.sh`. Modul `verify` creează două baze noi separate și execută 01→02→03 în fiecare. În a doua bază, testele Etapei 1 cu rollback preced încărcarea și avansează ID-urile; comparația finală normalizează după coduri și perioade. Sunt prevăzute auditul datasetului, testele cronologiei și refuzul încărcărilor duplicate. Acesta este mecanismul de replay verificat de runner; restaurarea dump-ului nativ nu este testată (`restore_tested=false`). Cele două replay-uri au trecut și sunt identice după normalizare.

Modul `main` cere o verificare reușită pentru checksum-urile exacte ale fișierelor urmărite și compară fingerprint-ul schemei principale cu schema verificată. Pentru o bază nepopulată salvează mai întâi un backup prin mariadb-dump, apoi execută direct 02/03, auditul doar în citire și comparația normalizată cu replay-ul. Nu rulează 01 în baza principală. Datele parțiale sau necunoscute sunt păstrate și provoacă refuzul populării. Pentru un dataset deja complet și identic, repetarea face comparația și auditul doar în citire, apoi întoarce `ALREADY POPULATED`, fără DML.

Logurile și manifestele se scriu în `verification/phase2/`; backup-ul anterior populării este `exports/two_clocks_cabd_before_phase2_<stamp>.sql`, iar exportul final este `exports/two_clocks_cabd_phase2.sql`. După popularea reușită runnerul completează tx_id reale în CSV; statusurile documentare se actualizează separat la final. Wrapper-ele necesită Python 3 pentru orchestrare; livrabilele SQL rămân standalone. Autentificarea folosește mecanismul local existent; nu se stochează credențiale. Baza principală a fost populată și auditată efectiv.

02/03 rulează standalone pe schema existentă, prin client MariaDB care procesează DELIMITER, fără generatoare Python la runtime. Blocurile BEGIN NOT ATOMIC au tranzacții explicite și handler ROLLBACK/RESIGNAL. GET_LOCK în namespace-ul bazei serializează replay-urile cooperante; cursoarele blochează toate ancorele în ordine PK, club → player → coach → contract → rol. Timpul local v_time este capturat o dată per eveniment prin fn_effective_time(), apoi reutilizat. Snapshot-urile temporare I4 și Q0 sunt verificate înainte de COMMIT. [Protocolul complet](docs/data_plan.md) explică și gestionarea erorilor; nu se modifică schema și nu se implementează A1.

### Story log — 38 de evenimente proiectate

Toate momentele TT de mai jos sunt UTC, cu precizie de microsecunde; toate cele 38 de evenimente au fost comise și verificate. Data efectivă descrie schimbarea, inclusiv noul sfârșit la E5 și data corectată la T19. Fereastra de transfer [2025-07-01, 2025-09-01) este fictivă. Prefixele păstrate la E2 nu sunt evenimente E3 noi; Q3 folosește metadatele evenimentelor și istoricul SQL.

| Ref | Etichete | Data efectivă VT | TT UTC | Poveste și motiv |
|---|---|---|---|---|
| T01 | E1 | 2025-07-01 | 2025-07-01 09:00:00.000000 | Încărcare inițială: persoane fictive, cluburi, două sezoane, contracte și titulari; CL04 are două angajamente adiacente cu H05. |
| T02 | E3 | 2025-08-31 | 2025-09-10 14:00:00.000000 | Transfer P001 la FC Târnava, înregistrat după închiderea ferestrei fictive. |
| T03 | E3 | 2025-08-30 | 2025-09-15 14:00:00.000000 | Transfer P002 la FC Ardeal, înregistrat târziu. |
| T04 | E3 | 2025-08-29 | 2025-09-22 14:00:00.000000 | Transfer P003 la FC Mureș, înregistrat târziu. |
| T05 | E2 | 2025-11-01 | 2025-10-05 10:00:00.000000 | FC Someș anunță majorarea bugetului pentru noiembrie. |
| T06 | E3 | 2025-08-28 | 2025-10-12 14:00:00.000000 | Transfer P004 la FC Apuseni, înregistrat târziu. |
| T07 | E3 | 2025-08-27 | 2025-10-20 14:00:00.000000 | Transfer P005 la FC Criș, înregistrat târziu. |
| T08 | E2 | 2025-12-01 | 2025-11-10 10:00:00.000000 | FC Ardeal anunță bugetul din decembrie. |
| T09 | E2 | 2026-01-01 | 2025-12-01 10:00:00.000000 | FC Mureș anunță bugetul din ianuarie. |
| T10 | E5 | 2025-12-01 | 2025-12-03 14:00:00.000000 | P013 părăsește real CL02 la 1 decembrie. |
| T11 | E5 | 2025-12-15 | 2025-12-18 14:00:00.000000 | P014 părăsește real CL02 la 15 decembrie. |
| T12 | E5 | 2025-12-20 | 2025-12-23 14:00:00.000000 | P015 părăsește real CL02 la 20 decembrie. |
| T13 | E3, E5 | 2026-01-01 | 2026-01-08 14:00:00.000000 | Plecare P016 de la CL02, înregistrată cu șapte zile întârziere. |
| T14 | E5 | 2026-01-15 | 2026-01-18 14:00:00.000000 | P017 părăsește real CL02 la 15 ianuarie. |
| T15 | E2, E6 | 2026-02-01 | 2026-01-20 10:00:00.000000 | Revenirea P013 este anunțată pentru februarie, pe aceeași ancoră. |
| T16 | E3, E7 | 2026-01-10 | 2026-01-20 14:00:00.000000 | H08 îl înlocuiește pe H03 la CL02 din 10 ianuarie. |
| T17 | E2, E6 | 2026-03-01 | 2026-02-15 10:00:00.000000 | Revenirea P014 la CL02 este anunțată pentru martie. |
| T18 | E3, E7 | 2026-03-01 | 2026-03-10 14:00:00.000000 | CL01 înregistrează demiterea/înlocuirea H01 cu H02, inițial datată 1 martie. |
| T19 | E3, E4 | 2026-03-03 | 2026-03-15 11:00:00.000000 | Corecție T18: data reală a înlocuirii este 3 martie, nu 1 martie. |
| T20 | E3, E6 | 2026-03-10 | 2026-03-20 14:00:00.000000 | P015 revine la CL02 după pauză; revenirea este înregistrată târziu. |
| T21 | E3 | 2026-04-01 | 2026-04-10 14:00:00.000000 | Afirmație eronată: P060 ar fi împrumutat la CL06 în aprilie. |
| T22 | E2 | 2026-05-01 | 2026-04-15 10:00:00.000000 | Salariul P025 va crește din mai; se păstrează prefixul cu 1250 EUR. |
| T23 | E3, E4 | 2025-07-01 | 2026-04-20 10:00:00.000000 | Corectează salariul inițial P026 la 1280 EUR. |
| T24 | E3, E4 | 2025-07-01 | 2026-04-22 10:00:00.000000 | Corectează salariul inițial P027 la 1290 EUR. |
| T25 | E8 | 2026-04-01 | 2026-04-25 10:00:00.000000 | Retrage împrumutul T21 pentru [2026-04-01,2026-05-01) ca niciodată adevărat; închide numai TT, fără înlocuire. |
| T26 | E3, E4 | 2026-05-01 | 2026-05-10 10:00:00.000000 | Corectează T22 numai în sufixul din mai; prefixul anterior rămâne. |
| T27 | E2 | 2026-06-01 | 2026-05-15 10:00:00.000000 | Anunță salariul P026 din iunie, plecând de la valoarea corectată. |
| T28 | E3 | 2026-06-01 | 2026-06-10 10:00:00.000000 | Împrumut P006 la CL02 până în septembrie, fără închiderea contractului de origine. |
| T29 | E3 | 2026-06-01 | 2026-06-10 11:00:00.000000 | Împrumut P007 la CL03, înregistrat cu nouă zile întârziere. |
| T30 | E3 | 2026-06-01 | 2026-06-10 12:00:00.000000 | Împrumut P008 la CL04, înregistrat cu nouă zile întârziere. |
| T31 | E2 | 2026-07-01 | 2026-06-15 10:00:00.000000 | Anunță salariul P027 din iulie, păstrând valoarea inițială corectată. |
| T32 | E5 | 2026-07-01 | 2026-07-05 10:00:00.000000 | Scurtează real împrumutul P006: se încheie la 1 iulie, nu 1 septembrie. |
| T33 | E3, E4 | 2026-07-01 | 2026-07-10 10:00:00.000000 | Corectează T31 numai în sufixul din iulie la 1495 EUR. |
| T34 | E2, E9 | 2026-08-01 | 2026-07-15 10:00:00.000000 | O singură decizie majorează bugetul CL04 și salariul P037 din august. |
| T35 | E2, E9 | 2026-09-01 | 2026-08-15 10:00:00.000000 | O singură decizie majorează bugetul CL05 și salariul P049 din septembrie. |
| T36 | E2, E7 | 2026-10-01 | 2026-09-01 10:00:00.000000 | H01 este anunțat la CL03 din octombrie, după plecarea din CL01. |
| T37 | E2 | 2026-11-01 | 2026-09-10 10:00:00.000000 | CL06 anunță bugetul din noiembrie înainte să devină valabil. |
| T38 | E2, E6 | 2026-10-01 | 2026-09-20 10:00:00.000000 | Reîncepe împrumutul P006 pe aceeași ancoră, după pauza iulie–octombrie. |

## Livrabile Part C realizate și pașii de predare rămași

- **Implementat și verificat** — `04_views.sql`: Q0 consecvent cu schema și Q1–Q8: fapte actuale, mandate coalescate, clasificare E2/E3/E4 cu valori vechi/noi, intersecție/acoperire sezon, snapshot TT, punct bitemporal A → B → A, calendar lunar cu zero și pauze între relații.
- **Implementat și verificat** — `05_tests.sql`: parametri și ieșiri pentru toate view-urile, limite [from,to), Q6; EXPLAIN cu/fără index este în scripts/compare_q6_index.sh. Interogările de audit ale Etapei 2 nu reprezintă livrarea view-urilor Q1–Q8.
- Raport de maximum cinci pagini, diagramă și rulare 01–05 de la zero. Termen: **Seminarul 3**; predare `CABD Team/Assignment1/boar_victor`.
- Bonus A1: API de proceduri pentru TT; bonus A2: implementare temporală nativă separată. Ambele rămân neimplementate.

Execuțiile și tx_id reale sunt confirmate în [rezumatul etapei 2](verification/phase2_summary.md).

## Dovezi finale Part B

Etapa 2 este completă: [rezumatul verificării](verification/phase2_summary.md), [reconstrucție și export](docs/replay.md). Două replay-uri identice, 67 expected și 483 aserțiuni de cronologie per bază, populare principală verificată și export complet. Repetarea populate_main a confirmat ALREADY POPULATED fără DML.

## Etapa 3 / Part C — Q0–Q8 și dovezi EXPLAIN

**Status: completă, verificată în două baze noi și instalată de două ori în principală fără modificarea datelor de business.** Q0–Q8 PASS; 52 scenarii pozitive și 4 verificări Q0 suplimentare în clone.

Livrabile: `04_views.sql`, `05_tests.sql`, [catalogul interogărilor](docs/query_catalog.md), `docs/query_expected_results.json`, `scripts/verify_queries.sh`, `scripts/install_views_main.sh`, `scripts/compare_q6_index.sh`, exportul `exports/phase3_views.sql` și [rezumatul execuției](verification/phase3_summary.md). Ultimul rezumat și manifestele din `verification/phase3/` stabilesc statusul real.

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
# Reconstruiește numai în DOUĂ baze noi, cu nume unice:
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/verify_queries.sh"
# Experimentul EXPLAIN creează propria clonă; nu elimină indexuri în principală:
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/compare_q6_index.sh"
# Backup + instalează NUMAI view-uri; 05 pozitiv; păstrează business data:
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/install_views_main.sh"
# Inspecție/teste pozitive standalone; restaurează query_params:
pkexec /usr/bin/mariadb --database=two_clocks_cabd < "$CABD_PROJECT_ROOT/05_tests.sql"
```

`04_views.sql` poate fi rerulat: CREATE OR REPLACE VIEW, în ordinea dependențelor. Nu recreează tabele și nu elimină indexuri/trigger-e. **01_schema.sql recreează obiecte și șterge date: nu îl executa pe principala populată.** Installerul verifică checksum-urile aceleiași versiuni testate, salvează backup complet și `previous_views.sql`, apoi compară înainte/după toate rândurile de business (inclusiv ID-uri), separat de parametri. DDL-ul view-urilor produce commit implicit; revenirea se face controlat folosind definițiile salvate, nu prin ROLLBACK.

Rerularea `install_views_main.sh` este verificată separat. Runnerul păstrează bazele și logurile de verificare. Schema manuală, funcția ceasului și cele 16 trigger-e rămân active. După adăugarea view-urilor, vechiul `populate_main.sh` din etapa 2 poate refuza fingerprint-ul extins al schemei; acesta este un installer istoric de date, nu comanda pentru etapa 3.

### DBeaver / parametri

Refresh pe conexiunea existentă, selectează `two_clocks_cabd`, deschide SQL Editor și confirmă `SELECT DATABASE();`. Exemple:

```sql
SET time_zone='+00:00';
UPDATE query_params SET subject_id=(SELECT club_id FROM club WHERE club_code='CL01'),
 valid_at='2026-03-02',known_at='2026-03-12 12:00:00.000000',
 period_start='2025-07-01',period_end='2026-07-01' WHERE params_id=1;
SELECT * FROM v_q6_bitemporal_point ORDER BY fact_kind,subject_code,valid_from;
SELECT * FROM v_q3_event_audit ORDER BY tx_time,fact_family,subject_code;
SELECT * FROM v_q7_monthly_relationships ORDER BY month_start,club_code;
SELECT * FROM v_q8_relationship_gaps ORDER BY player_code,club_code,gap_from;
SELECT COUNT(*) AS violation_count FROM v_integrity_violations;
-- Preset final al demonstrației A -> B -> A:
UPDATE query_params SET known_at='2026-03-16 12:00:00.000000' WHERE params_id=1;
```

05 conține `DELIMITER $$` și `BEGIN NOT ATOMIC`; folosește Execute SQL Script cu delimitatorii procesați sau execuția nativă MariaDB. CLI este calea executată efectiv; GUI DBeaver nu este declarat testat. Folosește o sesiune fără tranzacție deschisă. Modul implicit are numai SELECT și UPDATE query_params plus obiecte temporare de aserțiune; nu creează rutine permanente. Parametrii se restaurează și la eroare.

Demonstrațiile Q0 negative sunt activate numai de runner în clonele nou create, prin flag și numele exact al bazei; principală este refuzată explicit. Fiecare fixture este anulat prin ROLLBACK și Q0 redevine zero. Capturile sunt CSV UTF-8 per scenariu, cu fișiere JSON pentru parametrii reali; Q3 include auditul complet. Expected-ul etapei 2 este păstrat nemodificat.

Q1/Q2 consemnează ziua UTC reală; celelalte demonstrații folosesc parametri ficși. Duratele infinite nu sunt afișate ca mii de ani. Q7 numără relații distincte pe fereastră lunară, inclusiv zero, nu versiuni salariale. Q8 unește adiacența înainte de calculul golurilor. Q3 păstrează etichetele multiple și compară toate valorile/datele vechi și noi.

Următorul pas: **Part D**, raportul de maximum cinci pagini, selecția dovezilor și verificarea pachetului de predare. A1/A2 se decid separat. Acest stadiu nu declară raportul ori predarea finalizate.
