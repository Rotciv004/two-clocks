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

{{STORY_LOG}}
