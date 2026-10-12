# Etapa 4 — raport, diagramă și pachet verificat

Autor: **Boar Victor**. Audit final: 10 octombrie 2026. Director: `/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks/`.

**Core A–D pregătit pentru predare.** Nu s-a încărcat nimic în CABD Team, nu s-au trimis mesaje, nu s-a publicat nimic și nu s-au creat commituri. Bonusurile A1/A2 nu sunt implementate și nu sunt incluse fișiere bonus fictive. Termenul rămâne înainte de Seminar 3, fără dată calendaristică inventată.

## 1. Surse și protecții

Au fost citite PDF-urile nemodificate Course1/Assignment1 din `docs/references/`, README, 01–05, modelul/protocolul, cronologia/story log, expected-urile, catalogul Q0–Q8, cele trei rezumate anterioare și logurile/CSV-urile primare relevante, inclusiv EXPLAIN. Nu a fost găsit AGENTS.md aplicabil. SHA-256 ale SQL-urilor, oracle-ului Part C și runnerului istoric sunt identice cu manifestul Etapei 3 reușite; PDF-urile corespund provenienței originale. Dovezi: `phase4/source_audit.json` și `docs/report_evidence_map.md`.

Pe principala `two_clocks_cabd` s-au executat **numai SELECT/SHOW/metadate**, prin autentificarea locală existentă `pkexec` și MariaDB. Nu s-a rulat 01, nu s-au schimbat date, istoric, conturi, parole, configurația serverului sau query_params. Instalarea serverului existent nu a fost modificată. `server.log` confirmă hostname **VictorPC**, **11.8.8-MariaDB**, `root@localhost`, sesiune UTC.

Backupurile documentelor modificate sunt `phase4/README.before.md`, `requirements_matrix.before.md` și `er_diagram.before.dot`. Diferența DOT este păstrată în `diagram_changes.diff`: numai `labelloc=b` pentru grupul tehnic, fără modificări de schemă. Sursele SQL originale sunt păstrate integral.

## 2. Verificări NOI, executate în această etapă

Un singur replay final al fișierelor din **propriul pachet** `submission/boar_victor/`, într-o bază nouă:

`two_clocks_cabd_verify_p3_submission_20261010_185944_56a7d1a9`

Lanț: **01→02→03→04→05**, cu cele 16 trigger-e de gardă active. Autentificarea Polkit a fost finalizată; nu s-a introdus parola în conversație, argumente sau loguri. Lansarea a fost făcută din `/tmp`; pkexec a stabilit working directory efectiv `/root`, consemnat de manifest. Ambele sunt în afara pachetului. Runnerul a citit explicit fișierele distribuite, nu SQL-urile originale.

| Verificare | Rezultat nou / sursă primară |
|---|---|
| 52 scenarii pozitive Q0–Q8 + 4 verificări Q0 suplimentare | PASS; `phase4/replay_package_1/05_tests.log`, `results/`, `manifest.json` |
| Regresii dataset / cronologie | PASS, 67 cazuri și 483 aserțiuni; `dataset_assertions.log`, `timeline_assertions.log` |
| Q0 după toate rollback-urile | 0; `q0_after_rollbacks.log` |
| Fixture-uri și parametri | Anulate/restaurați; business și query_params ale clonei identice înainte/după teste |
| Business normalizat | Egal cu referința verificată a Etapei 2, după coduri, perioade și referințe Tnn; ID-urile nu sunt criteriu de egalitate |
| Q0–Q8 normalizate | Egale cu referința Etapei 3; ID-uri și coloanele dependente de ziua evaluării sunt excluse din comparația între rulări |
| Q1/Q2 efective | UTC_DATE=2026-10-10; P006: CL01/PERMANENT/1060.00 și CL02/LOAN/650.00; Q2 CL04/H05, elapsed_days=466 |
| Q6 | H01→H02→H01 pentru CL01, VT 2026-03-02; înainte/exact/după frontierele T18/T19 la ±1µs confirmate |
| Q7/Q8 | Toate 72 valori lună×club comparate; CL06 iulie 2025=0; toate patru golurile de 62/76/80/92 zile |
| Exemplu intenționat greșit Q2 | SELECT DISTINCT fără coalescing produce două mandate H05, expected independent unul; demonstrație read-only în clona nouă, nu istoric inventat al dezvoltării |

Numărători noi: player=60, coach=8, club=6, season=2, contract=69, head_coach_role=6; club_version=18, contract_version=98, head_coach_role_version=15, **131 versiuni**; tx_registry=38, tx_event_tag=53. **77** fapte contractuale curente TT. Etichete E1…E9: **1,13,18,5,6,4,3,1,2**. Dovezi: `phase4/postflight.json`, normalizările și manifestul replay-ului.

Demonstrația Q2 este păstrată integral în `q2_without_coalescing.sql/.json`. Actual: H05 `[2025-07-01,2026-07-01)` și `[2026-07-01,9999-12-31)`; expected independent: `[2025-07-01,9999-12-31)`. View-ul corect nu a fost modificat.

## 3. Principala neschimbată — aceeași metodă fingerprint

Înainte **și** după replay:

```text
74d4a44650b438f64ef7f010e9bce2893b68ac7483072a9ca2483e08aaa520c8
```

Metoda este exact `phase3_runner.business`: SELECT * ORDER BY 1,2 pentru cele 11 tabele business, rândurile reprezentate prin șiruri; `json.dumps(data, ensure_ascii=False, sort_keys=True)` și SHA-256. Nu se compară hashuri obținute prin metode diferite. query_params este exclus din acest hash și comparat separat. Structura (coloane, indexuri, FK, trigger-e, funcție, view-uri) și query_params sunt identice înainte/după.

Probe: `phase4/replay_package_1/main_business_before.json`, `main_business_after.json`, `main_structure_before/after.json`, `main_params_before/after.json`, toate SHOW CREATE din `main_ddl_*.log` și `main_view_*.log`, manifestul și `phase4/postflight.json`. Pachetul include fingerprintul/manifestul, metadatele structurale și normalizarea datasetului; nu dublează backupuri administrative ale datelor principalei.

## 4. Rezultate ANTERIOARE, reinspectate fără a pretinde rerulare

- Cele două replay-uri Etapa 3 cu ID-uri diferite și rezultate normalizate egale, regresiile și instalarea repetată sigură a view-urilor rămân probe istorice din `verification/phase3/`; sursele lor sunt identificate în harta dovezilor.
- Cele 230 aserțiuni schema-smoke și 37 probe writer din etapele anterioare **nu au fost rerulate** în Etapa 4. Fișierele sunt păstrate pentru reproducere și rezumatele istorice sunt distribuite separat.
- Experimentul EXPLAIN este cel efectiv anterior din `phase3/explain_20261009_073306_d03aa8/`, copiat integral în `submission/boar_victor/evidence/explain/`. Aceeași clonă/parametri: CL03, VT 2026-05-05, TT 2026-05-11 12:00 UTC. Cu as-of: v=ALL, key=NULL, rows estimate=98. Fără: a=ref/ix_contract_club/14, v=ref/ix_p3_contract_fk_support/1. Rezultatele sunt egale; as-of a fost restaurat și suportul temporar eliminat în clonă. Nu s-a măsurat accelerare și `rows` nu înseamnă rânduri efectiv procesate.
- Probleme istorice demonstrate de loguri: Q3 ERROR 1111 (rezolvat prin helper materializat), ERROR 1267 în regresiile vechi (collation doar de sesiune), schema-smoke rulat după view-uri (număra și coloanele lor; mutat înainte de 04). Logurile exacte sunt în `phase4/historical_failures/` și în pachet.

## 5. Raport și diagramă — verificare finală

`report.pdf`: **5 pagini totale A4**, fără copertă/anexă suplimentară, autor Boar Victor; corp 10,1 pt, tabele 8 pt și cod 8,1 pt, fonturi Noto încorporate, paginare. Sunt prezente toate cinci secțiunile Part D, SQL reale E3/T18, E4/T19, E8/T25 și distincția E5 în VT versus E8 în TT. Fragmentele complete executabile sunt copiate verbatim din 03 în `docs/report_write_examples.sql`, cu precondiții pentru momentul exact al replay-ului, coduri în loc de ID-uri presupuse, lock-uri, handler ROLLBACK/RESIGNAL, Q0/I4 și COMMIT. Nu se rulează pe principala complet populată.

Raportul include output-uri CLI reale pentru fiecare Q0–Q8, Q3 toate **33 componente / 31 evenimente** în proiecție compactă (JSON complet în CSV), Q5 toate **77 fapte** în trei blocuri și Q7 toate **72 valori** în pivot. Q4 este etichetat explicit extras; Q2 este un output real de un rând, iar Q6 are toate trei perspective și probele microsecundelor. EXPLAIN păstrează toate **șapte rânduri din fiecare plan** în proiecție type/key/rows/Extra; logurile integrale includ toate coloanele. Toate tabelele provin programatic din surse și sunt comparate automat, nu completate manual.

Referințele cursului indică pagini pentru VT/TT/chei și concurență/MVCC; comparația Oracle/SQL Server/PostgreSQL 18/19 separă VT, TT, I1–I4. Funcționalitatea anticipată FOR PORTION OF din Assignment pentru PostgreSQL 19 nu este prezentată ca facilitate stabilă demonstrată: documentația oficială consultată nu o confirmă. Modelul core MariaDB rămâne manual; trigger-ele nu sunt prezentate drept bonus A1 complet.

Sursă editabilă: `docs/report.md`; generator: `scripts/build_report.py`; dependențe fixate: `docs/report_requirements.txt`. Generarea nu apelează servicii externe; mediul `.report-venv` este local și exclus din pachet. Fonturile necesare și licența OFL sunt incluse explicit pentru reproducere offline.

Diagrama: `er_diagram.dot`, `er_diagram.pdf`, `er_diagram.png`. Toate **12 tabele**, coloanele reale, PK/FK/UQ și **11 relații** au fost comparate cu schema și metadatele serverului. Sunt arătate crow’s-foot, UNIQUE(player_id,club_id), UNIQUE(club_id) al rolului, legăturile versiunilor la registru, nouă tabele non-temporal/trei bitemporale și query_params fără FK arbitrar. Singura ajustare a fost eticheta grupului tehnic, nu baza.

Control automat: `phase4/pdf_checks.json`, `report_layout.json`, `diagram_audit.json`. **Toate cele cinci pagini finale** au fost randate și inspectate vizual, inclusiv după ultima modificare EXPLAIN. PDF-ul/PNG-ul diagramei au fost inspectate: lizibile, fără text tăiat. Dovezi vizuale: `phase4/report_final-1.png`…`-5.png`, `er_diagram_render.png`, `visual_review.md`.

## 6. Pachet și arhivă — verificare efectivă

Director: `submission/boar_victor/`. ZIP: **`submission/boar_victor_assignment1.zip`**. Selecție explicită: README cu toate 38 evenimente, 01–05, teste și runnerul portabil, documentația relevantă, report/diagramă/surse, fonturi/licență și dovezi complete citate. Sunt excluse credențiale, configurații DBeaver personale, cache-uri, venv, dumpuri/backupuri administrative, baze de test și PDF-urile cursului.

Nu există USE/SOURCE/DEFINER fix în 01–05 sau dependență runtime de directorul/contul original. Runnerul include autentificare prin fișier privat existent, fără parole în argumente; privilegii și politici CREATE FUNCTION documentate, fără relaxarea protecțiilor serverului. Erorile neanticipate produc exit nenul; nu se folosește --force. CREATE DATABASE fără IF NOT EXISTS refuză coliziunile și 01 este permis numai în baza nou creată de runner.

ZIP-ul final a fost **extras** în `/tmp/cabd-submission-extracted-vp02ogz5/boar_victor`, verificat CRC și prin `MANIFEST.sha256`: **192 fișiere**, fiecare identic cu selecția finală. Toate fișierele runtime din copia extrasă sunt byte-identice cu cele din replay-ul PASS. Modificările ulterioare replay-ului sunt exclusiv documente/PDF/generator de raport; SQL-urile și runnerul testat sunt neschimbate. Prin urmare nu s-a repetat inutil replay-ul SQL după finalizarea documentelor.

Raportul a fost **regenerat offline din fișierele copiei extrase**, pornind din `/tmp`, fără inputuri SQL/fonturi/CSV din proiectul original. Interpreterul Python local oferă numai bibliotecile fixate; toate inputurile raportului provin din ZIP. PDF-ul regenerat este byte-identic cu cel final inspectat și cu cel distribuit. Manifestul a fost reverificat după build, fără modificarea fișierelor extrase. Dovezi: `phase4/archive_validation.json`, `extracted_validation.json`, `extracted_report_build/report_layout.json`.

SHA-256 ZIP:

```text
e090106cd54d632347d74696edc222f259b39c7da4be241545137e86ee04f410
```

SHA-256 report.pdf (proiect = pachet = extras = regenerat):

```text
4401ff057c83d1e03dc0e0802de3ff529b100fd369e8bc1b84af5aae9b91800e
```

SHA-256 er_diagram.pdf (proiect = pachet = extras):

```text
1a37cd1302ebbb4ee10a0390ffa97e5ce98bf0a95f0df51e6ffe746aa5da616b
```

Checksumurile sunt în `submission/SHA256SUMS`; manifestul integral este `submission/boar_victor/MANIFEST.sha256`, copiat și în `phase4/submission_manifest.sha256`.

## 7. Comenzi exacte și limite

Comenzile de mai jos descriu operațiile efectuate; replay-ul cu directorul de dovezi deja existent NU se repetă identic (runnerul refuză suprascrierea).

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
cd /tmp
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/verify_submission.sh" \
  --package-root "$CABD_PROJECT_ROOT/submission/boar_victor" \
  --evidence-dir "$CABD_PROJECT_ROOT/verification/phase4/replay_package_1" \
  --main-database two_clocks_cabd

cd "$CABD_PROJECT_ROOT"
.report-venv/bin/python scripts/build_report.py \
  --evidence-root verification/phase4/replay_package_1 --output report.pdf
python3 scripts/check_report.py
pdftoppm -scale-to 1600 -png report.pdf verification/phase4/report_final
dot -Tpdf er_diagram.dot -o er_diagram.pdf
dot -Tpng -Gdpi=150 er_diagram.dot -o er_diagram.png
python3 scripts/audit_phase4.py
python3 scripts/prepare_phase4.py finalize
.report-venv/bin/python scripts/check_submission_archive.py
cd submission
sha256sum -c SHA256SUMS
```

Pentru un replay suplimentar folosește un director NOU, ca în README-ul pachetului: `mktemp -d`, apoi `--evidence-dir "$CABD_EVIDENCE/replay"`; niciodată 01 pe principală. Baza de test nouă și directoarele temporare extrase sunt păstrate, nu șterse automat. Curățarea este exclusiv manuală, după verificarea numelui exact din manifest; nu există script care șterge principala.

**Limite reale:** GUI DBeaver, restaurarea nativă a dumpurilor și stresul concurent între sesiuni rămân netestate. Instrucțiunile nu sunt prezentate drept teste executate. Calea de reconstrucție demonstrată este replay-ul SQL 01→05. Nu se declară bonusuri implementate, performanță măsurată sau notă garantată. A/B/C au dovezi istorice și noul replay; D este finalizat și verificat în această etapă.
