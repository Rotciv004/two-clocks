# Catalog Q0–Q8 — Part C

Toate perioadele sunt [from,to). VT DATE, TT DATETIME(6), UTC. Santinelele sunt capete deschise convenționale, nu momente de evaluare. Codurile provin din ancore; ID-urile nu sunt presupuse consecutive. View-urile nu garantează ordinea: SELECT-ul demonstrativ are ORDER BY.

| Întrebare / view | Parametri | Granularitate / regulă |
|---|---|---|
| Q0 `v_integrity_violations` | niciunul | Diagnostice I1/I2/I3 pentru TT curent; I2 unește intervalele părinte prin running MAX și gaps-and-islands |
| Q1 `v_q1_current_contracts` | subject_id=player_id | Un fapt contractual activ la UTC_DATE(), TT curent; numele clubului selectat tot astăzi/curent |
| Q2 `v_q2_coach_tenures` | subject_id=club_id | Un mandat coalescat, pe poziție stabilă; numai TT curent |
| Q3 `v_q3_event_audit` | niciunul | tx_id + fact_family + subject_code; 31 evenimente, 33 componente |
| Q4 `v_q4_period_relationships` | period_start/end | Un rând contract_version curent; overlap strict și containment inclusiv al limitelor |
| Q5 `v_q5_contracts_as_known` | known_at | Toate faptele contractuale la TT, fără valid_at/subiect/filtru TT curent |
| Q6 `v_q6_bitemporal_point` | subject_id=club_id,valid_at,known_at | UNION ALL HEAD_COACH și CONTRACT, fiecare un fapt; fără produs titular×jucători |
| Q7 `v_q7_monthly_relationships` | period_start/end | Club×lună; COUNT(DISTINCT contract_id) cu overlap al ferestrei lunare limitate la perioada cerută |
| Q8 `v_q8_relationship_gaps` | niciunul | Gol între două insule VT consecutive ale aceleiași ancore; numai TT curent |

`query_params` trebuie să conțină exact un rând. PK/CHECK permit cel mult unul; 05 validează existența. Q3/Q4/Q5/Q7/Q8 nu moștenesc filtrul subiectului dintr-un scenariu anterior. Q1 folosește UTC_DATE real, niciodată @sim_now. Exemplele fixe Q6 sunt etichetate distinct.

## Q2: mandate și durate

LAG identifică schimbarea titularului sau discontinuitatea; SUM numerotează insulele în ordinea perioadelor pe role_id. Numai perioadele adiacente ale aceluiași titular se reunesc. O revenire după alt titular ori gol rămâne separată. CL04/H05 devine [2025-07-01,9999-12-31), din două rânduri curente. CL01 este H01 până la 3 martie, apoi H02.

`tenure_days=DATEDIFF(tenure_to,tenure_from)` pentru capăt finit, NULL pentru santinelă. `elapsed_days=GREATEST(DATEDIFF(LEAST(UTC_DATE(),tenure_to),tenure_from),0)`. `tenure_status` este SCHEDULED / ACTIVE / ENDED. Politica păstrează angajamentele viitoare. I1 validat prin Q0 este precondiția lipsei suprapunerilor pe rol.

## Q3: proveniență, valori și frontiera efectivă

Helperul `v_p3_audit_facts` normalizează cele trei istorice. `v_p3_audit_events` păstrează toate etichetele pentru evenimente cu E2/E3/E4. Componentele provin din versiunile afirmate prin tx_id; pentru contracte subiectul este jucătorul, iar business_key păstrează perechea cu clubul. E9 are două componente, un singur eveniment.

`old_values` sunt rândurile închise la timpul evenimentului, restrânse la familie/subiect; nu se asociază old.tx_id cu tx_id de închidere. `new_values` sunt rândurile cu tx_id al evenimentului. Colecțiile JSON sunt ordonate după cheia perechii și valid_from și au obiecte cu business_key, value, agreement_kind, valid_from, valid_to. Nicio multiplicare old×new. NULL old_values înseamnă lipsa unei credințe precedente închise în această componentă (fapt nou/restart); perioadele anterioare finite rămân în istoric.

Frontiera este începutul unui rând nou cu valoare diferită de vechea valoare la același punct VT, sau începutul unei noi relații. Dacă numai capătul se scurtează, se folosește noul valid_to. La corecția frontierei rolului se folosește începutul noului sufix: T19 3 martie, nu 1 iulie al prefixului și nici 1 martie al credinței greșite. Această regulă descrie operațiile existente ale cronologiei, fără ramuri hardcodate după Tnn. Prefixele apar în proveniență, dar nu creează evenimente.

T19 JSON arată H01 până la 1 martie / H02 din 1 martie înainte, apoi H01 până la 3 martie / H02 din 3 martie. Consecința pentru 2 martie H02→H01 este demonstrată în Q6. T13 folosește capătul 2026-01-01, deci întârzierea este 7 zile. `delay_days=DATEDIFF(DATE(tx_time),effective_date)` are semn; `lead_days=GREATEST(-delay_days,0)`.

În cronologia livrată, cele 38 de momente sunt distincte, verificat înainte de audit. Schema nu impune unicitate globală. `same_time_events` și `ambiguous_closure` expun o eventuală ambiguitate; pentru un timestamp duplicat, helperul nu inventează asocierea rândurilor închise, iar 05 oprește auditul. Valorile provin din SQL, nu din reason/CSV; doar referința narativă este LEFT(reason,3).

Helperul de candidați este materializat (`ALGORITHM=TEMPTABLE`) pentru a separa subinterogările corelate de agregarea frontierelor în MariaDB. JSON_ARRAYAGG ordonat: [documentație oficială](https://mariadb.com/docs/server/reference/sql-functions/aggregate-functions/json_arrayagg). Nu este o API de scriere și nu implementează A1.

## Q4–Q8: interpretări

Q4 numără fapte salariale, nu durata cumulată a perechii peste mai multe salarii. `throughout` cere ca un singur rând să conțină întreaga perioadă. Q5 include fapte VT deja încheiate și viitoare; la 21 septembrie sunt 77.

Q6 păstrează subject_code/name ca antrenor sau jucător după fact_kind; agreement_kind/salary_eur sunt NULL pentru rol. Nu atașează club_version, deci nu poate amesteca nume de club din alt snapshot.

Q7 generează lunile prin [CTE recursiv](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/selecting-data/common-table-expressions/recursive-common-table-expressions-overview), pornind de la luna period_start până înainte de period_end. Nu se extinde spre santinelă. Testele folosesc maximum 12 luni; pentru analize lungi respectă limita de sesiune max_recursive_iterations și utilizează perioade finite rezonabile. Prima și ultima fereastră sunt intersecții cu perioada cerută. LEFT JOIN păstrează zero; salary splits nu dublează ancora. În august un transfer poate contribui la două cluburi în părți diferite ale lunii.

Q8 proiectează mai întâi relația independent de salariu, unește adiacența/suprapunerea prin running MAX, apoi LAG găsește numai goluri strict pozitive. Perechile și restarturile sunt P013–CL02/T15 (62 zile), P014–CL02/T17 (76), P015–CL02/T20 (80), P006–CL02/T38 (92).

## Apel și teste

```sql
SET time_zone='+00:00';
UPDATE query_params SET subject_id=(SELECT club_id FROM club WHERE club_code='CL01'),
 valid_at='2026-03-02',known_at='2026-03-12 12:00:00.000000' WHERE params_id=1;
SELECT * FROM v_q6_bitemporal_point ORDER BY fact_kind,subject_code,valid_from;
UPDATE query_params SET subject_id=(SELECT player_id FROM player WHERE player_code='P006') WHERE params_id=1;
SELECT * FROM v_q1_current_contracts ORDER BY club_code,valid_from;
```

05 este standalone, cu BEGIN NOT ATOMIC și DELIMITER; nu depinde de Python sau SOURCE. Expected-urile sunt materializate din modelul literal independent în docs/query_expected_results.json. Generatorul local este numai pentru autorare. Cele 52 de scenarii pozitive compară rândurile și valorile, nu doar counts; Q3 compară toate 33 componente, inclusiv toate obiectele JSON vechi/noi; Q7 compară întreaga matrice. Expected-urile dinamice Q1/Q2 folosesc intervale literale și UTC_DATE(), nu rezultatul view-ului.

Mod implicit: modificări doar în query_params, cu salvare/restaurare inclusiv pe eroare. Necesită sesiune fără tranzacție deschisă. Fixture-urile Q0 au tranzacții proprii și ROLLBACK, cu trigger-ele active. Activarea cere simultan @p3_negative=1, @p3_test_database identic cu DATABASE() și prefixul verificării; principală este refuzată explicit. Runnerul creează baza unică și injectează numele. Acesta este un gard operațional pentru script, nu un sistem de privilegii împotriva administratorului care poate seta variabile arbitrare.

Fiecare scenariu emite marker, parametri și rezultat ordonat; runnerul salvează CSV UTF-8 și JSON cu parametrii. Q0 curat include count=0 și antetul diagnosticului. Capturile negative sunt separate; după fiecare rollback Q0 este verificat din nou.
