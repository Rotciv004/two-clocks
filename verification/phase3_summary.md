# Etapa 3 / Part C — Q0–Q8, teste și EXPLAIN

## Gazdă și preflight

Execuție efectivă: **2026-10-09 UTC**, VictorPC, Fedora 44, MariaDB **11.8.8-MariaDB**, autentificare locală existentă root@localhost prin pkexec. Directorul exact: `/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks/`.

[Preflight read-only](phase3/preflight.log): contract_version 98, registru 38, Q0 zero, query_params singleton, cele 16 trigger-e, definiția funcției fn_effective_time și indexul as-of real. Fișierele etapelor anterioare, expected-ul Part B, PDF-urile și diagrama sunt păstrate; hashurile inițiale sunt în [preserved_files_before.json](phase3/preserved_files_before.json).

## Execuții izolate și rezultate

[Manifest final de verificare](phase3/verify_20261009_072839_ef3341/manifest.json). Baze noi:

- `two_clocks_cabd_verify_p3_20261009_072839_ef3341_1`;
- `two_clocks_cabd_verify_p3_20261009_072839_ef3341_2`.

În fiecare: 01 → 02 → 03 → 04 → 05, apoi 04/05 rerulate **fără replay al datelor**. A doua bază are ID-uri diferite, avansate natural prin testele cu rollback, fără manipularea AUTO_INCREMENT. Datele și rezultatele normalizate pe coduri/perioade/valori sunt identice.

Fiecare 05 în clonă: **52 scenarii pozitive + 4 verificări Q0 = 56 aserțiuni de scenariu**. Fiecare scenariu compară colecția completă de rânduri/valori cu expected independent. Nu se numără fiecare rând drept aserțiune separată. Prima și a doua execuție, în ambele clone: PASS. CSV UTF-8 și parametrii JSON sunt în [capturi prima clonă](phase3/verify_20261009_072839_ef3341/1_05_results/) și directorul corespunzător celei de-a doua.

Teste suplimentare ale runnerului: guard activat pe principală și nume greșit de test → respingere exactă P3_GUARD, înainte de fixture; parametrii și business data nemodificate. O eroare de citire introdusă controlat prin lipsa temporară a Q1 **numai în clonă** demonstrează restaurarea parametrilor pe eroare; 04 recreează apoi view-ul. Nu există fixture-uri persistente.

Regresii **rerulate în această etapă**: 230 aserțiuni schema smoke (în a doua bază, înainte de view-urile noi), 37 verificări de exemple de scriere după recrearea Q0, 67 cazuri dataset și 483 aserțiuni timeline în fiecare clonă. Nu sunt doar numere preluate din raportul anterior.

| Întrebare | Verdict și dovadă |
|---|---|
| Q0 | PASS: zero final; I1 contract exact, I3 rol exact (și I1 asociat), I2 acoperire prin două intervale adiacente validă și gol real detectat; ROLLBACK după fiecare fixture |
| Q1 | PASS: UTC_DATE()=2026-10-09; P006 are PERMANENT CL01 1060.00 și LOAN CL02 650.00 |
| Q2 | PASS: CL04/H05 coalescat într-un mandat deschis, tenure_days NULL, elapsed_days 465; CL01 frontiera corectată 3 martie |
| Q3 | PASS: toate **31 evenimente / 33 componente**, 13 E2 / 18 E3 / 5 E4, toate valorile/datele vechi/noi și etichetele comparate |
| Q4 | PASS: 77 fapte, overlap/containment pe două sezoane și limite exacte/atingere fără overlap |
| Q5 | PASS: 77 după cronologia completă; neschimbat la schimbarea valid_at/subiect; snapshot-uri înainte/exact T21 și T25 |
| Q6 | PASS: ambele familii, trei perspective, VT 1/3 martie și TT exact/±1µs; transfer, împrumut scurtat, retractare, salariu corectat |
| Q7 | PASS: 72 rânduri sezon1, toate cele 72 valori din matrice, sezon2 și perioade parțiale; zero păstrat și salary splits nedublate |
| Q8 | PASS: exact cele patru goluri, fără frontiere salariale interpretate ca pauze |

Expected-ul [query_expected_results.json](../docs/query_expected_results.json) este materializat din cronologia literală independentă, fără citirea rezultatelor view-urilor. Matricea Q7 din prompt a fost verificată și separat înainte de utilizare: [calcul independent](phase3/monthly_oracle_check.json).

### Q6: trei perspective, VT 2026-03-02, CL01

| known_at UTC | Rezultat |
|---|---|
| 2026-03-05 12:00:00.000000 | H01 — Andrei Ionescu |
| 2026-03-12 12:00:00.000000 | H02 — Mihai Popescu |
| 2026-03-16 12:00:00.000000 | H01 — Andrei Ionescu |

Cele cinci versiuni istorice CL01 sunt păstrate. CSV separate: `Q6_perspective_1.csv`, `_2.csv`, `_3.csv`, fiecare cu fișier params JSON.

### Q8: pauze

| Pereche | De la | Până la | Zile | Restart |
|---|---|---|---:|---|
| P013–CL02 | 2025-12-01 | 2026-02-01 | 62 | T15 |
| P014–CL02 | 2025-12-15 | 2026-03-01 | 76 | T17 |
| P015–CL02 | 2025-12-20 | 2026-03-10 | 80 | T20 |
| P006–CL02 | 2026-07-01 | 2026-10-01 | 92 | T38 |

## EXPLAIN real pe Q6

[Manifest](phase3/explain_20261009_073306_d03aa8/manifest.json), [SQL exact](phase3/explain_20261009_073306_d03aa8/query.sql), [DDL și metadate](phase3/explain_20261009_073306_d03aa8/index_metadata.log), [plan cu index](phase3/explain_20261009_073306_d03aa8/explain_with_index.log), [plan fără](phase3/explain_20261009_073306_d03aa8/explain_without_index.log), planuri JSON în același director.

Clonă dedicată `two_clocks_cabd_verify_p3_20261009_073306_d03aa8_explain`. Query real: `SELECT * FROM v_q6_bitemporal_point WHERE fact_kind='CONTRACT' ORDER BY subject_code,valid_from,version_id`, CL03, VT 2026-05-05, TT 2026-05-11 12:00 UTC. Dataset identic de 98 versiuni contractuale.

Indexul inspectat: `ix_contract_version_asof(contract_id,tx_to,valid_from)`. Susține și FK contract_id. Înainte de eliminare s-a creat `ix_p3_contract_fk_support(contract_id)` pentru păstrarea suportului FK. La final indexul as-of a fost recreat, iar cel auxiliar eliminat; principală nu a fost atinsă de experiment.

| Plan | Acces contract_version | key | rows estimate |
|---|---|---|---:|
| Cu as-of | ALL | NULL | 98 |
| Fără as-of, cu suport FK simplu | ref | ix_p3_contract_fk_support | 1 per ancoră |

În planul fără as-of, contract este selectat prin ix_contract_club, estimare 14 ancore. Ramura HEAD_COACH este eliminată ca Impossible WHERE de filtrul fact_kind. Rezultatele complete sunt egale; business fingerprint rămâne identic. Nu s-a folosit FORCE INDEX, nu se afirmă accelerare și nu s-au măsurat timpi de benchmark. Sunt planuri ale optimizerului pe datasetul mic al assignmentului.

## Principală, backup și păstrarea datelor

**Instalare principală: PASS.** [Manifest](phase3/main_20261009_073229_1a92c6/manifest.json). `04_views.sql` și `05_tests.sql` pozitiv au fost executate pe `two_clocks_cabd`. Nici 01, nici popularea nu au fost executate pe principală.

Fingerprint determinist al tuturor celor 11 tabele de business, cu ID-uri și coloane complete, separat de query_params:

- înainte: `74d4a44650b438f64ef7f010e9bce2893b68ac7483072a9ca2483e08aaa520c8`;
- după: `74d4a44650b438f64ef7f010e9bce2893b68ac7483072a9ca2483e08aaa520c8`;
- identitate: **True**. Coloanele/indexurile/trigger-ele/funcția au rămas identice.

Backup complet înainte de această instalare: `two_clocks_cabd_before_phase3_20261009_073229_1a92c6.sql`, SHA256 `86b9824247558871e74ccae75e2120485934930f8910bf011abfa4be942fdd05`. Definițiile view-urilor de dinainte sunt în [previous_views.sql](phase3/main_20261009_073229_1a92c6/previous_views.sql). DDL-ul se revine prin definițiile salvate, nu prin ROLLBACK.

Rulări reușite ale installerului: **2**. A doua rulare a confirmat rerularea sigură, 52 scenarii pozitive și același fingerprint.

Parametrii finali: VT 2026-03-02, TT 2026-03-16 12:00:00.000000, [2025-07-01,2026-07-01), subject_id rezolvat prin CL01. Există exact un rând; parametrii salvați înainte de fiecare test sunt restaurați, iar installerul aplică explicit acest preset.

Export: `exports/phase3_views.sql` obținut din **SHOW CREATE VIEW** pentru toate view-urile instalate, în ordinea dependențelor. Păstrează ALGORITHM, SQL SECURITY și DEFINER reale; nu este backup complet. Calificatorii sursei trebuie inspectați înainte de folosirea într-o altă schemă.

Numărătorile obligatorii înainte și după: player 60, coach 8, club 6, season 2, contract 69, head_coach_role 6, club_version 18, contract_version 98, head_coach_role_version 15, tx_registry 38, tx_event_tag 53. Total versiuni 131. Presetul este separat de fingerprint.

## Probleme reale întâlnite

- Prima definiție Q3 combina subinterogări corelate cu agregarea frontierelor; MariaDB a returnat ERROR 1111 Invalid use of group function. S-au separat candidații într-un helper materializat și agregarea într-un helper ulterior. Datele/expected-urile nu au fost schimbate.
- Regresiile vechi foloseau collation implicit diferit de view-urile Part C și au primit ERROR 1267. Runnerul aliniază SET NAMES la utf8mb4_unicode_ci numai pentru execuția testelor vechi după view-urile noi; fișierele originale sunt păstrate. Smoke-ul structural rulează în collation-ul original înainte de 04.
- Smoke-ul structural numără coloanele temporale din INFORMATION_SCHEMA fără a separa view-urile; după instalarea Q1–Q8 raporta mai mult de trei tabele bitemporale. Ordinea de regresie a fost corectată: smoke înainte de 04, exemplele de scriere și demonstrațiile Q0 după 04. Nu s-a relaxat nicio aserțiune a datasetului.

Logurile încercărilor eșuate sunt păstrate în directoarele verify anterioare manifestului final. Nicio eroare neașteptată nu este transformată în PASS global; fiecare eșec a oprit rularea.

## Repetare și limite

Comenzile CLI și pașii DBeaver sunt în [README](../README.md), contractele în [query_catalog.md](../docs/query_catalog.md). 04 recreează numai view-uri; 01 recreează tabele și este rezervat reconstrucției în baze noi. 05 implicit este sigur pentru principală și restaurează parametrii.

GUI DBeaver și restaurarea nativă a dumpurilor nu au fost testate. Reconstrucția 01–05 a fost executată în două baze noi. Nu s-au implementat A1/A2, report.pdf sau pachetul final. Următorul pas este **Part D: raport ≤5 pagini, selecția dovezilor și verificarea predării**.
