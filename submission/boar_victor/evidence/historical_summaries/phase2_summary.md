# Etapa 2 / Part B — executată și verificată

Execuție pe VictorPC, Fedora 44, MariaDB 11.8.8-MariaDB, autentificare locală existentă pkexec/root socket. Data logurilor: 2026-10-08 UTC (2026-10-09 în Europe/Bucharest). Director: `/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks`.

## Dovezi și ordine

1. Inspecție read-only: [initial_inspection.log](phase2/initial_inspection.log). Principala avea toate tabelele de business goale și un query_params.
2. [Verificare PASS](phase2/verify_20261008_215031_8588ef/manifest.json): două baze noi `two_clocks_cabd_verify_p2_20261008_215031_8588ef_1` și `_2`; 01 → 02 → 03 executate integral. Fiecare are 67 cazuri expected independente trecute și 483 aserțiuni de cronologie trecute. Auditul SQL verifică aceleași 67 expected; acestea nu sunt 134 cazuri independente.
3. În a doua bază s-au rerulat efectiv testele etapei 1: 230 aserțiuni, inclusiv 120 respingeri așteptate, și 37 verificări pentru exemplele de scriere. Fixture-urile au fost anulate prin ROLLBACK și au avansat natural ID-urile.
4. Replay-urile au ID-uri surrogate diferite, dar istoricul normalizat pe coduri/perioade este identic. SHA256 normalizat: `124aa0837bdb2a772b35cba0845180d191bcebb202945f4a11d5ee2d783ce00e`.
5. [Populare principală PASS](phase2/main_20261008_215218_588f2d/manifest.json): backup real, apoi numai 02 → 03, 67 cazuri verificate, comparație integrală cu replay-ul, export complet. 01 nu a fost executat pe principală. Schema, trigger-ele, funcția ceasului și exportul structural al etapei 1 sunt păstrate.
6. Repetarea populate_main.sh a returnat `ALREADY POPULATED: verified identical; replay refused, no data changed.` A repetat auditul cu 67 cazuri; fără DML. Manifestul separat din phase2 consemnează această execuție.

## Numărători reale comparate cu expected

| Obiect | Actual | Expected |
|---|---:|---:|
| player | 60 | 60 |
| coach | 8 | 8 |
| club | 6 | 6 |
| season | 2 | 2 |
| contract | 69 | 69 |
| head_coach_role | 6 | 6 |
| tx_registry | 38 | 38 |
| tx_event_tag | 53 | 53 |
| club_version total / curent TT | 18 / 12 | 18 / 12 |
| contract_version total / curent TT | 98 / 77 | 98 / 77 |
| head_coach_role_version total / curent TT | 15 / 10 | 15 / 10 |
| Total versiuni | 131 | 131 |
| Ancore contractuale cu versiuni curente | 68 | 68 |
| query_params | 1 | 1 |

E1–E9, schimbări distincte per etichetă: **1, 13, 18, 5, 6, 4, 3, 1, 2**, identic planului. Efectele, datele E2/E3 și valorile vechi/noi sunt testate, nu doar etichetele.

Q0: **0** după fiecare T01–T38 în ambele replay-uri și în principală; **0** final. Auditul verifică și I1–I3 în 38 de snapshot-uri istorice, cu același known_at pentru părinți/copii și uniunea intervalelor părinte.

I4: comparație înainte/după fiecare eveniment pentru toate versiunile vechi; numai închiderea tx_to permisă. Teste negative UPDATE/DELETE cu mesajul exact așteptat, rollback E9 după eșecul celei de-a doua componente, respingerea încărcărilor duplicate și absența fixture-urilor persistente: PASS. Limitele TT sunt verificate la −1µs, exact și +1µs.

## Rezultate demonstrative

VT `2026-03-02`, CL01, cinci versiuni de rol în istoric:

| known_at UTC | Rezultat |
|---|---|
| 2026-03-05 12:00:00 | H01 / Andrei Ionescu |
| 2026-03-12 12:00:00 | H02 / Mihai Popescu |
| 2026-03-16 12:00:00 | H01 / Andrei Ionescu |

Pauze pe aceeași ancoră: P013–CL02 **62 zile**, P014–CL02 **76**, P015–CL02 **80**, P006–CL02 **92**. Sunt verificate coalescing CL04/H05, transferul întârziat P001, corecțiile salariale, împrumutul scurtat, retractarea T25 fără înlocuire, E9 pe două tabele, luna zero CL06, overlap/containment sezon și acoperirea prin uniunea versiunilor clubului.

Relații active: **58** la VT 2026-09-21, **59** la VT 2026-10-15, ambele cu known_at fix 2026-09-21 12:00 UTC. La execuție, UTC_DATE() a fost 2026-10-08, UTC_TIMESTAMP(6) 2026-10-08 21:52:19.393769, cu **59** relații active. Numărul activ într-o zi nu este numărul faptelor curente TT.

query_params final: params_id=1, valid_at=2026-03-02, known_at=2026-03-16 12:00:00.000000, period_start=2025-07-01, period_end=2026-07-01, subject_id=1, ID-ul real CL01 rezolvat prin cod.

## Fișiere și reconstrucție

- `02_data.sql`: T01 atomic; `03_timeline.sql`: T02–T38, fiecare atomic.
- `tests/03_dataset_assertions.sql`, `tests/04_timeline_assertions.sql`: audit dataset și cronologie/fixture-uri izolate.
- `scripts/verify_dataset.sh`, `scripts/populate_main.sh`, `scripts/phase2_runner.py`: orchestrare, loguri, checksum-uri, refuz duplicare.
- `docs/data_plan.md`, `docs/timeline.csv` (38 evenimente cu tx_id reale), `docs/timeline_plan.json`, `docs/expected_results.json`, README story log și matrice cerințe.
- Backup: `exports/two_clocks_cabd_before_phase2_20261008_215218_588f2d.sql`, SHA256 `ea4c6c9af677d1ea1c26f1668e7cae537375738f8a743e1d995f29f041ba42e9`.
- Export complet real: `exports/two_clocks_cabd_phase2.sql`, SHA256 `c71e01a0a206a3ea3654e20ba232c0e574e7b6c25199bfefaf878183586eb703`; include date, funcție și trigger-e.

Reconstrucția **testată** este replay-ul în două baze noi, cu protecțiile active. Restaurarea nativă a dumpului **nu a fost testată**. Comenzile exacte echivalente sunt în [docs/replay.md](../docs/replay.md). Nu se declară exportul drept restaurare testată.

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
# Creează două baze noi și reconstruiește acolo obiectele prin 01:
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/verify_dataset.sh"
# Principală deja populată: verifică identitatea, fără replay sau resetare:
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/populate_main.sh"
# Inspecție doar în citire:
pkexec /usr/bin/mariadb --database=two_clocks_cabd -e 'SELECT VERSION(); SELECT * FROM query_params; SELECT * FROM v_integrity_violations;'
```

DBeaver: deschide conexiunea existentă → selectează two_clocks_cabd → SQL Editor → execută SELECT-urile de mai sus; Q0 nu are rânduri. Pentru inspecția datasetului deschide tests/03_dataset_assertions.sql și folosește Execute SQL Script sau clientul nativ MariaDB pentru DELIMITER. Tests/04 este exclusiv pentru bazele de test. **01 recreează obiecte; nu îl rula pe principala populată.**

## Problemă reală întâlnită și limite

Prima rulare de verificare a trecut replay-ul și 67 expected, apoi testul cronologiei a primit ERROR 1267: collation a sesiunii/tabelelor temporare diferită de schema utf8mb4_unicode_ci. S-a corectat numai SET NAMES în test și generatorul lui, adăugând COLLATE utf8mb4_unicode_ci. Logul eșuat este păstrat în `phase2/verify_20261008_214808_032e46`. Cele două replay-uri reușite folosesc baze noi. Schema și datele nu au fost relaxate.

Nu s-a făcut un test de concurență între sesiuni. Nu există blocaje rămase pentru Part B. Bazele de verificare și dovezile sunt păstrate; alte baze nu au fost modificate. Q1–Q8 finale, raportul și bonusurile rămân neimplementate. Următorul pas: **04_views.sql și 05_tests.sql pentru Q0–Q8**.
