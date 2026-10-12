# Two Clocks

Proiect pentru Assignment 1 — „Build a Bitemporal Database”, la disciplina Advanced Database Chapters and Cloud Databases.

Autor: Boar Victor. Motor testat: MariaDB 11.8.8, InnoDB, utf8mb4.

## Domeniu și model

Baza descrie o ligă fictivă de fotbal: jucători, cluburi, contracte, împrumuturi, bugete și antrenori. Fiecare fapt temporal păstrează două perioade:

- Valid time (VT): când faptul este valabil în realitate, cu tipul `DATE`.
- Transaction time (TT): când faptul este cunoscut de bază, cu tipul `DATETIME(6)`, în UTC.

Intervalele sunt semi-deschise, `[start, end)`. Capetele deschise folosesc `9999-12-31` pentru VT și `9999-12-31 23:59:59.999999` pentru TT. Identitățile sunt separate de versiuni; corecțiile închid versiunea în TT și inserează rânduri noi, fără rescrierea istoricului.

Exemplul central este titularul postului de antrenor la FC Someș, la 2 martie 2026:

| Cunoașterea la data UTC | Răspuns |
|---|---|
| 5 martie, 12:00 | H01 — Andrei Ionescu |
| 12 martie, 12:00 | H02 — Mihai Popescu |
| 16 martie, 12:00 | H01 — Andrei Ionescu |

Modelul temporal este implementat manual. Bonusurile A1 și A2 nu sunt implementate.

## Fișiere principale

| Fișier | Conținut |
|---|---|
| `01_schema.sql` | Tabele, constrângeri, indexuri, funcția ceasului și trigger-e de protecție |
| `02_data.sql` | Datele inițiale și evenimentul T01 |
| `03_timeline.sql` | Evenimentele T02–T38 |
| `04_views.sql` | Q0–Q8 și view-urile auxiliare |
| `05_tests.sql` | Scenarii, rezultate așteptate și verificări |
| [report.pdf](report.pdf) | Raportul de cinci pagini |
| [er_diagram.pdf](er_diagram.pdf) | Diagrama ER; sursele DOT și PNG sunt în același director |
| `submission/boar_victor/` | Pachetul de predare, cu dependențe și dovezi |

`00_create_database.sql` creează baza locală `two_clocks_cabd`. Pentru o demonstrație separată, folosește un nume nou, ca în exemplul de mai jos.

## Instalare într-o bază nouă

Cerințe: MariaDB 11.8.x și clientul `mariadb`. Rulează comenzile din rădăcina proiectului, cu un cont care poate crea baza, tabele, view-uri, trigger-e și rutine. Politica serverului poate cere privilegii suplimentare pentru `CREATE FUNCTION`.

`01_schema.sql` recreează obiectele și șterge datele lor. Nu îl rula pe baza populată `two_clocks_cabd`.

```bash
CABD_DB='two_clocks_demo_new'
(
  set -e
  mariadb --batch -e "CREATE DATABASE \`$CABD_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  for CABD_SQL in 01_schema.sql 02_data.sql 03_timeline.sql 04_views.sql 05_tests.sql; do
    mariadb --batch --raw --default-character-set=utf8mb4 \
      --database="$CABD_DB" < "$CABD_SQL"
  done
)
```

Crearea bazei refuză un nume existent; la eroare, instalarea se oprește. Ordinea este 01 → 02 → 03 → 04 → 05. Clientul MariaDB procesează `DELIMITER` și blocurile `BEGIN NOT ATOMIC`; nu folosi `--force`.

Comenzile presupun autentificarea existentă a utilizatorului. Un fișier privat de conexiune se poate indica prin `--defaults-extra-file=/cale/privata/client.cnf`, ca prim argument al clientului. Pe Fedora, pentru accesul administrativ local se poate folosi `pkexec /usr/bin/mariadb`. Nu salva parole în proiect sau în argumentele comenzilor.

## Verificare automată

Runnerul necesită Python 3 și clientul MariaDB. Citește SQL-urile din pachetul de predare și creează o bază de test cu nume unic. Baza și rezultatele sunt păstrate.

```bash
CABD_PACKAGE="$(pwd)/submission/boar_victor"
CABD_EVIDENCE="$(mktemp -d /tmp/two-clocks-verify-XXXXXX)"
(
  cd /tmp
  bash "$CABD_PACKAGE/scripts/verify_submission.sh" \
    --package-root "$CABD_PACKAGE" --evidence-dir "$CABD_EVIDENCE/replay"
)
```

Pentru autentificarea administrativă locală, înlocuiește `bash` cu `pkexec /usr/bin/bash`. Runnerul acceptă și `--defaults-extra-file /cale/privata/client.cnf`.

Testele negative Q0 sunt activate numai în baza nouă creată de runner. Fixture-urile sunt anulate prin `ROLLBACK`; parametrii și datele sunt verificate înainte și după teste. Opțiunea `--main-database two_clocks_cabd` adaugă inspecția read-only și comparația fingerprintului bazei principale.

Verificarea din 10 octombrie 2026 a trecut 52 de scenarii pozitive, 4 verificări Q0, 67 de cazuri dataset și 483 de aserțiuni de cronologie. Datele principalei au rămas neschimbate. Rezultatele și limitele testării sunt în [verification/phase4_summary.md](verification/phase4_summary.md).

## Interogare Q6

Exemplu pentru CL01, VT 2 martie și cunoașterea din 12 martie. Se rulează în baza instalată, într-o sesiune fără tranzacție deschisă:

```sql
SET time_zone = '+00:00';
START TRANSACTION;

UPDATE query_params
SET subject_id = (SELECT club_id FROM club WHERE club_code = 'CL01'),
    valid_at = '2026-03-02',
    known_at = '2026-03-12 12:00:00.000000'
WHERE params_id = 1;

SELECT subject_code, subject_name
FROM v_q6_bitemporal_point
WHERE fact_kind = 'HEAD_COACH';

ROLLBACK;
```

Rezultatul este H02 — Mihai Popescu. `ROLLBACK` restaurează parametrii. Q1 și Q2 folosesc ziua UTC a execuției; celelalte întrebări au parametrii descriși în [catalogul interogărilor](docs/query_catalog.md).

Pentru scripturile complete în DBeaver folosește execuția nativă MariaDB, care procesează delimitatorii. CLI este calea testată; interfața DBeaver, restaurarea nativă a dumpurilor și testarea concurentă între sesiuni nu au fost verificate.

## Documentație

- [Model și dicționar de date](docs/schema_design.md)
- [Protocol de scriere](docs/write_protocol.md)
- [Planul datelor și cronologia](docs/data_plan.md), [timeline.csv](docs/timeline.csv)
- [Cerințe și starea implementării](docs/requirements_matrix.md)
- [Exemplele SQL E3, E4 și E8](docs/report_write_examples.sql)
- [Sursele rezultatelor din raport](docs/report_evidence_map.md)

Sursele editabile ale raportului și diagramei sunt `docs/report.md` și `er_diagram.dot`. Generarea raportului folosește `scripts/build_report.py` și dependențele din `docs/report_requirements.txt`.

Materialele de curs, credențialele, dumpurile administrative și fișierele temporare sunt excluse din Git. Arhiva de predare și checksumurile sale sunt disponibile local în `submission/`; directorul `submission/boar_victor/` este versionat.

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


## Livrabile Part C

| Întrebare | View | Scop |
|---|---|---|
| Q0 | `v_integrity_violations` | Încălcări ale integrității temporale |
| Q1 | `v_q1_current_contracts` | Contractele active astăzi ale unui jucător |
| Q2 | `v_q2_coach_tenures` | Mandate de antrenor, cu perioade adiacente reunite |
| Q3 | `v_q3_event_audit` | Evenimente E2/E3/E4 și valori vechi/noi |
| Q4 | `v_q4_period_relationships` | Suprapunere sau acoperire a unei perioade |
| Q5 | `v_q5_contracts_as_known` | Toate faptele contractuale la un moment TT |
| Q6 | `v_q6_bitemporal_point` | Fapte la o dată VT, dintr-o perspectivă TT |
| Q7 | `v_q7_monthly_relationships` | Contracte distincte pe lună și club |
| Q8 | `v_q8_relationship_gaps` | Pauze între perioadele aceleiași relații |

Raportul și dovezile includ rezultatele Q0–Q8 și comparația EXPLAIN cu/fără indexul as-of. Pe datasetul testat, optimizerul nu a ales indexul as-of; nu este prezentat un benchmark de performanță.
