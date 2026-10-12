# Verificare efectivă — Two Clocks, etapa 1

**Status: etapa structurală implementată și verificată pe MariaDB-ul local.** Data execuțiilor: 7 octombrie 2026. Nu este întregul assignment terminat.

## Mediu și protejarea datelor

- Director: `/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks/`.
- Server confirmat prin SQL: `VictorPC`, socket `/var/lib/mysql/mysql.sock`, `11.8.8-MariaDB`, `root@localhost`.
- Sistem: Fedora 44 KDE, utilizator RotcivRaob; DBeaver 26.2.1; client MariaDB 11.8.8.
- Inspecția inițială nu a găsit baza principală sau alte baze `two_clocks_cabd%`. Directorul era gol, fără Git, fără AGENTS.md aplicabil pe calea proiectului. Nu existau date de proiect de salvat.
- Autentificarea folosită este cea locală existentă, prin pkexec. Nu s-au creat parole/conturi/granturi; nu s-au schimbat datadir, configurația globală sau expunerea în rețea.
- `information_schema.USER_PRIVILEGES` a confirmat permisiunile administrative existente, inclusiv CREATE/DROP, DML, TRIGGER, CREATE VIEW, CREATE ROUTINE, EXECUTE, CREATE TEMPORARY TABLES și SHOW VIEW. Nu au fost afișate hashuri sau parole.
- Sesiunea inițială: DATABASE() NULL, time_zone SYSTEM, sql_mode STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION. Sesiunile 01 și testele setează explicit UTC și mod strict. Logul principal citește într-o sesiune nouă și arată SYSTEM; aceasta nu schimbă convenția UTC a valorilor DATETIME scrise.

## Execuții și rezultate

| Verificare | Rezultat efectiv |
|---|---|
| Creare inițială schema pe baza de probă | PASS, exit 0; `initial_schema.log` nu are erori |
| Runner inițial | PASS: schema de două ori, 220 aserțiuni + 37 verificări de exemple |
| Runner final | PASS, exit 0: schema de două ori + **230 aserțiuni** + **37 verificări de exemple** |
| Schema | 12 tabele InnoDB, exact 3 bitemporale; perioade DATE/DATETIME(6), santinele și CHECK-uri confirmate |
| Indexuri/FK | Indexurile as-of, cheile și RESTRICT verificate prin INFORMATION_SCHEMA; SHOW CREATE TABLE în structure.log |
| I1 | Suprapuneri detectate pe fiecare din cele 3 chei; adiacența acceptată |
| I2 | Ambii copii testați: adiacență, suprapunere, interval imbricat, pauză reală, părinte lipsă, depășire stânga/dreapta |
| I3 | Doi titulari simultani detectați; schimbarea la limita exclusivă acceptată |
| I4 | UPDATE business/toate coloanele protejate, rând închis, redeschidere și DELETE respinse; PK/FK contract/rol protejate |
| Ceas | Valori calendaristice invalide, garbage, precizie >6 și viitor respinse; 0–6 zecimale și lipsa ceasului acceptate corect |
| E9 atomic | Un tx_id și timestamp comun pe 2 tabele; eroare salariu negativ urmată de rollback al întregii schimbări logice, registru și etichetă incluse |
| Parametri | Singleton actualizabil, al doilea rând și interval invalid respinse |
| Q0 valid | Zero încălcări pe fixture-urile valide, inclusiv exemplele E3/E4/E5/E8/E9 |
| Q0 invalid | Diagnostice efective I1/I2/I3 afișate înainte de ROLLBACK |
| Exemple documentate | SQL din write_protocol.md identic cu tests/02_write_examples.sql; 37/37 verificări trecute |
| Main | Instalat prin install_main.sh, exit 0; 12 tabele, Q0 și rândul tehnic exact |
| Export | mariadb-dump real: 12 CREATE TABLE, 16 trigger-e, 1 funcție, view Q0; fără date |
| Diagramă | Graphviz disponibil; PNG randat și inspectat vizual, fără instalări |

Cele 230 de aserțiuni sunt **110 verificări pozitive/de metadate și 120 erori așteptate**, recunoscute prin MYSQL_ERRNO și fragmentul mesajului. Codurile observate includ 1644 (SIGNAL), 4025 (CHECK), 1452 (FK), 1062 (unicitate) și 1048 (NOT NULL). Nu s-a folosit --force și nu s-au dezactivat trigger-ele.

## Cinci versiuni și trei perspective

Datele exacte t1 = 2025-07-01 09:00:00.000000, t2 = 2026-03-10 14:00:00.000000, t3 = 2026-03-15 11:00:00.000000 UTC au produs exact cinci rânduri pentru FC Someș.

| valid_at | known_at UTC | Rezultat real |
|---|---|---|
| 2026-03-02 | 2026-03-05 12:00:00.000000 | Ionescu |
| 2026-03-02 | 2026-03-12 12:00:00.000000 | Popescu |
| 2026-03-02 | 2026-03-16 12:00:00.000000 | Ionescu |

Au trecut și probele la t2/t3 exact, cu o microsecundă înainte/după, la începutul VT și la capătul exclusiv VT/TT. Cele cinci versiuni și cele trei răspunsuri sunt extrase din log în [three_perspectives.tsv](three_perspectives.tsv).

## Dovezi

- [Log final complet](two_clocks_cabd_verify_20261007_135833_21411_18721/run.log).
- [Aserțiuni și erori așteptate](two_clocks_cabd_verify_20261007_135833_21411_18721/01_schema_smoke.log).
- [Exemple E3/E4/E5/E8/E9](two_clocks_cabd_verify_20261007_135833_21411_18721/02_write_examples.log).
- [Metadate și SHOW CREATE TABLE](two_clocks_cabd_verify_20261007_135833_21411_18721/structure.log).
- [Prima recreare](two_clocks_cabd_verify_20261007_135833_21411_18721/schema_pass_1.log), [a doua recreare](two_clocks_cabd_verify_20261007_135833_21411_18721/schema_pass_2.log).
- [Starea finală a bazei principale](main_structure.log).
- [Respingeri, extrase din log](negative_results.tsv), [Q0, extrase din log](q0_diagnostics.tsv).
- [Export structural real](../exports/schema_only.sql), [diagrama PNG](../er_diagram.png).
- `latest_success.txt` indică directorul ultimei suite reușite; `file_manifest.sha256` identifică livrabilele finale.

Baze create și păstrate exclusiv pentru această sarcină:

1. `two_clocks_cabd_verify_initial_20261007_1645`: proba inițială DDL, fără fixture-uri.
2. `two_clocks_cabd_verify_20261007_135539_21158_17483`: prima suită, fixture-uri anulate.
3. `two_clocks_cabd_verify_20261007_135833_21411_18721`: suita finală, fixture-uri anulate.
4. `two_clocks_cabd`: baza principală; numai query_params are un rând. Celelalte 11 tabele au zero rânduri, confirmat în main_structure.log.

Nu au fost șterse baze și nu au fost modificate alte baze. Numerele AUTO_INCREMENT din bazele de test pot fi avansate după ROLLBACK; acesta este comportament normal, fără date persistente de fixture.

## Comenzi efectiv executate

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
pkexec /usr/bin/mariadb --batch -e 'SELECT VERSION(), CURRENT_USER(), DATABASE(), @@session.time_zone, @@session.sql_mode; SHOW DATABASES LIKE "two_clocks_cabd%";'
pkexec /usr/bin/mariadb --batch --database=two_clocks_cabd_verify_initial_20261007_1645 < "$CABD_PROJECT_ROOT/01_schema.sql"
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/verify_schema.sh"
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/install_main.sh"
```

Runnerul a fost executat de două ori și a creat de fiecare dată o bază nouă. Fiecare rulare a recreat schema de două ori. Instalatorul principal a fost executat o singură dată pe baza absentă; refuză ulterior bazele care au obiecte. Scripturile conțin comenzile exacte interne și opțiunile mariadb-dump. Verificarea statică `bash -n` a trecut pentru ambele scripturi.

## Probleme reale și limite

Accesul inițial la socket a fost blocat de sandbox (ERROR 2002), autentificarea fără parolă RotcivRaob a fost respinsă (ERROR 1045), iar sudo -n a cerut autentificare. Dialogul local pkexec a rezolvat accesul fără schimbări de configurare. Nu au existat eșecuri SQL neașteptate în suitele executate.

La revizuire s-au întărit comparațiile text cu BINARY și s-a aliniat fixture-ul la data exactă 2025-07-01, înaintea suitei finale. Acestea sunt ajustări reale, nu încercări SQL eșuate inventate.

Nu s-a executat GUI DBeaver, un test concurent de stres, EXPLAIN comparativ sau benchmark. Concurența se bazează pe protocolul comun documentat și pe blocarea ancorelor; I1–I3 rămân diagnostice Q0, nu restricții la INSERT. Etichetele sunt imutabile la UPDATE/DELETE, dar schema permite adăugarea unei etichete noi prin INSERT; protocolul le înregistrează împreună cu schimbarea. Un administrator cu DDL poate elimina protecții; gărzile se aplică DML-ului cu obiectele active.

Exportul structural nu conține query_params și nu a fost prezentat drept backup cu date. Nu există blocaje rămase pentru etapa 1. Încărcarea finală, cronologia completă, Q1–Q8, raportul final și A1/A2 sunt **planificate**, fără fișiere goale care să sugereze implementarea lor.
