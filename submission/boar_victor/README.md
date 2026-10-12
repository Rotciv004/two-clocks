# Two Clocks — Boar Victor

Assignment 1, Advanced Database Chapters and Cloud Databases. Domeniu: ligă fictivă de fotbal. Motor verificat: **MariaDB 11.8.8**, InnoDB, utf8mb4/utf8mb4_unicode_ci. Livrabile core A–D; bonusurile A1/A2 nu sunt implementate. Nu sunt incluse conturi, parole sau configurări personale. Termenul din assignment: înainte de Seminar 3; pachetul este pregătit pentru predare de către autor.

Stare audit final: **core A–D pregătit pentru predare**. Un replay NOU al propriilor fișiere 01→05 a trecut pe MariaDB 11.8.8: 52 scenarii pozitive + 4 verificări Q0, 67 cazuri dataset și 483 aserțiuni timeline. Capturile noi sunt în `evidence/replay/`; dovezile istorice sunt identificate separat. Raportul/diagrama au fost inspectate vizual, iar ZIP-ul a fost extras și verificat prin manifest. Baza principală a autorului a fost inspectată numai în citire: fingerprintul, structura și parametrii sunt neschimbați. Bonusurile A1/A2, GUI DBeaver și restaurarea nativă a dumpurilor nu sunt declarate testate/implementate.

## Instalarea într-o bază goală

Deschide terminalul în directorul extras `boar_victor/`. Folosește autentificarea MariaDB existentă. Exemplele `mariadb` presupun accesul contului curent; poți adăuga ca prim argument `--defaults-extra-file=/cale/privata/client.cnf`. Nu pune parola în argumente. Pe Fedora-ul autorului, accesul administrativ local verificat este `pkexec /usr/bin/mariadb`; nu este o dependență pentru alte calculatoare.

```bash
# Alege un nume NOU pentru demonstrație; nu reutiliza baza principală populată.
CABD_DB='two_clocks_demo_new'
(
  set -e
  mariadb --batch -e "CREATE DATABASE \`$CABD_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  for CABD_SQL in 01_schema.sql 02_data.sql 03_timeline.sql 04_views.sql 05_tests.sql; do
    mariadb --batch --raw --default-character-set=utf8mb4 --database="$CABD_DB" < "$CABD_SQL"
  done
)
```

`CREATE DATABASE` fără IF NOT EXISTS refuză numele existent. **01_schema.sql recreează obiectele și șterge datele lor**; rulează-l numai pe baza goală de demonstrație. 02 încarcă E1/T01; 03 comite T02–T38 în ordinea TT și refuză încărcarea duplicată; 04 creează/înlocuiește numai view-urile; 05 demonstrează Q0–Q8 și restaurează `query_params`. Fiecare fișier selectează baza din client, fără USE fix, SOURCE sau DEFINER fix. CLI MariaDB procesează `DELIMITER` și blocurile `BEGIN NOT ATOMIC`; nu folosi `--force`. Privilegiile necesare se limitează la baza selectată: DDL, FK, DML, VIEW, TRIGGER, CREATE/ALTER ROUTINE, EXECUTE și CREATE TEMPORARY TABLES; runnerul are în plus nevoie de CREATE DATABASE pentru numele unic. Politica locală de binary logging poate impune autorizare administrativă pentru CREATE FUNCTION; pachetul nu schimbă politica serverului.

## Replay automat și Q0 negativ

Verificarea portabilă pornește și din alt working directory, citește exclusiv propriul pachet și creează un nume unic `two_clocks_cabd_verify_p3_submission_…`. Păstrează baza și logurile; nu șterge baze. Necesită Python 3 (biblioteca standard) și CLI MariaDB.

```bash
CABD_PACKAGE="$(pwd)"
CABD_EVIDENCE="$(mktemp -d /tmp/cabd-submission-verify-XXXXXX)"
cd /tmp
bash "$CABD_PACKAGE/scripts/verify_submission.sh" \
  --package-root "$CABD_PACKAGE" --evidence-dir "$CABD_EVIDENCE/replay"
```

Pe laptopul autorului se poate executa același runner cu `pkexec /usr/bin/bash …`; este autentificarea administrativă locală existentă, fără schimbarea parolelor. Pentru un cont configurat prin fișier privat adaugă `--defaults-extra-file /cale/privata/client.cnf`. Opțional `--main-database two_clocks_cabd` efectuează numai SELECT/SHOW și compară fingerprintul înainte/după; nu este necesar pe un server de predare fără principală.

05 implicit rulează 52 scenarii pozitive. Fixture-urile negative Q0 au nevoie simultan de `@p3_negative=1`, `@p3_test_database=DATABASE()` și un nume cu prefixul autorizat `two_clocks_cabd_verify_p3_`. Runnerul creează acest nume și activează cele patru verificări Q0 suplimentare (I1, I3, acoperire I2 prin adiacență, gol I2). Fixture-urile sunt tranzacționale și se termină cu ROLLBACK; gărzile rămân active. Parametrii și toate datele de business sunt comparate înainte/după. Nu activa negativele pe principala completă. `tests/01_schema_smoke.sql` se rulează pe schema goală înainte de instalarea 04; suitele suplimentare sunt păstrate în `tests/`. Rezultatele anterioare și cele noi sunt diferențiate în `evidence/`.

## Inspecție și parametri

Acestea nu reconstruiesc obiecte. 05 salvează/restaurează rândul parametrilor; pentru o interogare proprie îl poți actualiza într-o tranzacție și restaura cu ROLLBACK:

```sql
SET time_zone='+00:00';
SELECT VERSION(), DATABASE(), CURRENT_USER();
SELECT COUNT(*) FROM v_integrity_violations;
START TRANSACTION;
UPDATE query_params SET subject_id=(SELECT club_id FROM club WHERE club_code='CL01'),
 valid_at='2026-03-02', known_at='2026-03-12 12:00:00.000000' WHERE params_id=1;
SELECT * FROM v_q6_bitemporal_point ORDER BY fact_kind,subject_code,valid_from;
ROLLBACK;
```

Numele publice sunt `v_integrity_violations`, `v_q1_current_contracts`, `v_q2_coach_tenures`, `v_q3_event_audit`, `v_q4_period_relationships`, `v_q5_contracts_as_known`, `v_q6_bitemporal_point`, `v_q7_monthly_relationships`, `v_q8_relationship_gaps`. Contractele parametrilor și SELECT-urile exacte sunt în `docs/query_catalog.md`, `docs/query_expected_results.json` și 05. Q1/Q2 folosesc ziua UTC efectivă a execuției; Q5 filtrează numai TT. CSV-urile și JSON-urile parametrilor sunt în `evidence/replay/results/`.

## Raport, diagramă și reproducere offline

`report.pdf` are cinci pagini A4. Sursa editabilă este `docs/report.md`, iar generatorul este `scripts/build_report.py`. Tabelele provin din CSV, inclusiv 33 componente Q3, toate 77 fapte Q5 și toate 72 valori Q7; proiecțiile și extrasele sunt etichetate. Folosește un mediu Python cu versiunile din `docs/report_requirements.txt`, apoi:

```bash
python3 scripts/build_report.py --evidence-root evidence/replay --output report.pdf
dot -Tpdf er_diagram.dot -o er_diagram.pdf
dot -Tpng -Gdpi=150 er_diagram.dot -o er_diagram.png
```

Generarea însăși nu contactează servicii externe. Fonturile și licența lor sunt în `docs/fonts/`. Diagrama este livrată separat în PDF vectorial, PNG și DOT, cu crow's-foot, PK/FK/UQ și clasificarea tabelului. CLI este calea verificată; GUI DBeaver și restaurarea nativă a dumpurilor rămân netestate. Reconstrucția verificată este replay-ul 01→02→03→04→05. Exporturile administrative și PDF-urile cursului nu sunt redistribuite. Referințe: Assignment1.pdf pp. 1–7, Course1.pdf pp. 12, 29–42 și URL-urile oficiale din raport/harta dovezilor.

Pentru curățare consultă numele exact al bazei create în `evidence/replay/manifest.json`; numai acea bază poate fi eliminată manual după verificarea numelui. Nu există script care șterge principala. Arhiva și fiecare fișier sunt protejate prin SHA-256; `MANIFEST.sha256` acoperă selecția distribuibilă.

## Story log complet — 38 evenimente

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
