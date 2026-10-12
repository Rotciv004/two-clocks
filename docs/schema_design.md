# Proiectarea schemei Two Clocks

## Scop, surse și starea documentului

Modelul descrie o ligă fictivă de fotbal: identități de jucători, antrenori și cluburi, relații contractuale care pot înceta și reîncepe, titulari ai poziției de antrenor principal și bugete variabile. Două ceasuri permit să răspundem atât „cine era antrenor la data V?”, cât și „ce știa baza despre acea dată la momentul T?”.

Sursele sunt cererea inițială „Two Clocks, partea 1: baza de date”, [Assignment1.pdf](references/Assignment1.pdf) și [Course1.pdf](references/Course1.pdf); textele consultate sunt `docs/references/Assignment1.txt` și `docs/references/Course1.txt`. Assignment definește evaluarea, iar cursul explică intervalele, coalescing, integritatea și stocarea temporală. Copiile PDF se află în `docs/references/` din directorul proiectului.

Schema și testele au fost executate pe serverul local MariaDB 11.8.8. Dovezile sunt în `verification/summary.md` și logurile aferente. Fișierele locale sunt distincte de baza logică `two_clocks_cabd` și de datadir-ul serverului.

## Cele 12 tabele și separarea responsabilităților

| Categorie | Tabele | Clasificare |
|---|---|---|
| 6 ancore / entități de domeniu | player, coach, club, season, contract, head_coach_role | non-temporal |
| 3 tabele de versiuni | club_version, contract_version, head_coach_role_version | bitemporal: VT + TT |
| 3 auxiliare tehnice | tx_registry, tx_event_tag, query_params | non-temporal, fără versionare proprie |

Cele șase entități de domeniu satisfac structural minimul de cinci; auxiliarele nu sunt numărate ca entități de domeniu. Numele și data nașterii jucătorilor/antrenorilor sunt fixe în acest assignment. `season` este o definiție fixă de interval, nu o entitate versionată. `contract` identifică perechea jucător–club, nu un document juridic; `head_coach_role` identifică poziția unui club, nu titularul. Un timestamp în registru nu transformă registrul într-un tabel TT.

Toate tabelele folosesc InnoDB, iar baza folosește utf8mb4 / utf8mb4_unicode_ci. Toate coloanele dicționarului sunt NOT NULL. Identificatorii și FK-urile sunt BIGINT UNSIGNED, cu excepția `params_id`. Cheile surrogate, inclusiv `tx_registry.tx_id`, sunt AUTO_INCREMENT; cheia compusă din `tx_event_tag` și singletonul nu sunt. Toate FK-urile au ON DELETE RESTRICT și ON UPDATE RESTRICT. Nu există cascade de ștergere a istoricului.

## Dicționarul tuturor coloanelor

### `player`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `player_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identitate stabilă |
| `player_code` | `VARCHAR(32)` | UNIQUE | Cod stabil al jucătorului |
| `full_name` | `VARCHAR(120)` | — | Nume considerat fix în model |
| `birth_date` | `DATE` | — | Data nașterii, considerată fixă |

### `coach`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `coach_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identitate stabilă |
| `coach_code` | `VARCHAR(32)` | UNIQUE | Cod stabil al antrenorului |
| `full_name` | `VARCHAR(120)` | — | Nume considerat fix în model |
| `birth_date` | `DATE` | — | Data nașterii, considerată fixă |

### `club`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `club_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identitate stabilă |
| `club_code` | `VARCHAR(32)` | UNIQUE | Cod stabil; numele și bugetul sunt în versiuni |

### `season`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `season_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identitate stabilă |
| `season_name` | `VARCHAR(32)` | UNIQUE | Denumirea perioadei de analiză |
| `period_start` | `DATE` | CHECK < period_end | Început inclusiv |
| `period_end` | `DATE` | CHECK > period_start | Sfârșit exclusiv |

### `contract`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `contract_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identitate stabilă |
| `player_id` | `BIGINT UNSIGNED` | FK → player.player_id | Referință obligatorie |
| `club_id` | `BIGINT UNSIGNED` | FK → club.club_id | Referință obligatorie |

### `head_coach_role`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `role_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identitate stabilă |
| `club_id` | `BIGINT UNSIGNED` | FK → club.club_id | Referință obligatorie |

### `club_version`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `version_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identificator fizic al versiunii |
| `club_id` | `BIGINT UNSIGNED` | FK → club.club_id | Referință obligatorie |
| `club_name` | `VARCHAR(120)` | — | Nume valabil în perioada respectivă |
| `budget_eur` | `DECIMAL(14,2)` | CHECK >= 0 | Buget în EUR |
| `valid_from` | `DATE` | — | Început inclusiv al valabilității |
| `valid_to` | `DATE` | DEFAULT '9999-12-31' | Sfârșit exclusiv al valabilității |
| `tx_from` | `DATETIME(6)` | — | Început inclusiv al credinței, UTC; egal cu tx_registry.tx_time |
| `tx_to` | `DATETIME(6)` | DEFAULT '9999-12-31 23:59:59.999999' | Sfârșit exclusiv al credinței, UTC |
| `tx_id` | `BIGINT UNSIGNED` | FK → tx_registry.tx_id | Referință obligatorie |

### `contract_version`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `version_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identificator fizic al versiunii |
| `contract_id` | `BIGINT UNSIGNED` | FK → contract.contract_id | Referință obligatorie |
| `agreement_kind` | `VARCHAR(9)` | CHECK IN ('PERMANENT', 'LOAN') | Contract permanent sau împrumut |
| `salary_eur` | `DECIMAL(12,2)` | CHECK >= 0 | Salariu în EUR |
| `valid_from` | `DATE` | — | Început inclusiv al valabilității |
| `valid_to` | `DATE` | DEFAULT '9999-12-31' | Sfârșit exclusiv al valabilității |
| `tx_from` | `DATETIME(6)` | — | Început inclusiv al credinței, UTC; egal cu tx_registry.tx_time |
| `tx_to` | `DATETIME(6)` | DEFAULT '9999-12-31 23:59:59.999999' | Sfârșit exclusiv al credinței, UTC |
| `tx_id` | `BIGINT UNSIGNED` | FK → tx_registry.tx_id | Referință obligatorie |

### `head_coach_role_version`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `version_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identificator fizic al versiunii |
| `role_id` | `BIGINT UNSIGNED` | FK → head_coach_role.role_id | Referință obligatorie |
| `coach_id` | `BIGINT UNSIGNED` | FK → coach.coach_id | Referință obligatorie |
| `valid_from` | `DATE` | — | Început inclusiv al valabilității |
| `valid_to` | `DATE` | DEFAULT '9999-12-31' | Sfârșit exclusiv al valabilității |
| `tx_from` | `DATETIME(6)` | — | Început inclusiv al credinței, UTC; egal cu tx_registry.tx_time |
| `tx_to` | `DATETIME(6)` | DEFAULT '9999-12-31 23:59:59.999999' | Sfârșit exclusiv al credinței, UTC |
| `tx_id` | `BIGINT UNSIGNED` | FK → tx_registry.tx_id | Referință obligatorie |

### `tx_registry`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `tx_id` | `BIGINT UNSIGNED` | PK, AUTO_INCREMENT | Identitate stabilă |
| `tx_time` | `DATETIME(6)` | Neunic | Momentul unic al schimbării logice, UTC |
| `author` | `VARCHAR(128)` | — | Autorul înregistrării |
| `reason` | `TEXT` | — | Motivul schimbării |

### `tx_event_tag`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `tx_id` | `BIGINT UNSIGNED` | PK compus; FK → tx_registry.tx_id | Schimbarea clasificată |
| `event_code` | `CHAR(2)` | PK compus; CHECK E1…E9 | Tipul evenimentului; mai multe etichete per schimbare |

### `query_params`

| Coloană | Tip | Cheie / regulă / implicit | Semnificație |
|---|---|---|---|
| `params_id` | `TINYINT UNSIGNED` | PK; CHECK = 1 | Singleton; fără AUTO_INCREMENT |
| `valid_at` | `DATE` | — | Data validă pentru interogare |
| `known_at` | `DATETIME(6)` | — | Momentul cunoașterii în UTC |
| `period_start` | `DATE` | CHECK < period_end | Începutul perioadei analizate |
| `period_end` | `DATE` | CHECK > period_start | Sfârșitul exclusiv al perioadei analizate |
| `subject_id` | `BIGINT UNSIGNED` | Fără FK | player_id sau club_id conform întrebării |

## Chei de business, cardinalități și identități

| Părinte → copil | Cardinalitate | Cheia externă |
|---|---|---|
| player → contract | 1 → 0..N | contract.player_id |
| club → contract | 1 → 0..N | contract.club_id |
| club → head_coach_role | 1 → 0..1 | head_coach_role.club_id, UNIQUE |
| club → club_version | 1 → 0..N | club_version.club_id |
| contract → contract_version | 1 → 0..N | contract_version.contract_id |
| head_coach_role → head_coach_role_version | 1 → 0..N | head_coach_role_version.role_id |
| coach → head_coach_role_version | 1 → 0..N | head_coach_role_version.coach_id |
| tx_registry → fiecare tabel de versiuni | 1 → 0..N | tx_id |
| tx_registry → tx_event_tag | 1 → 0..N | tx_event_tag.tx_id |

Fiecare copil are exact un părinte pentru fiecare FK. Ancorele pot exista înaintea versiunilor. `season` și `query_params` nu au FK. Rolul este unic per club, dar existența unui rol nu este impusă automat pentru orice club.

`UNIQUE(player_id, club_id)` pe contract face revenirile să utilizeze aceeași ancoră. `UNIQUE(club_id)` pe head_coach_role păstrează poziția stabilă când se schimbă antrenorul. Cheile temporale de business sunt club_id, contract_id și role_id. `version_id` identifică un rând, nu împiedică suprapunerea perioadelor. Contracte la cluburi diferite pot coexista; nu se impune unicitatea temporală globală pe jucător, deoarece modelul permite împrumuturi.

Protecțiile cerute pentru ancore resping UPDATE asupra contract_id/player_id/club_id din contract și role_id/club_id din head_coach_role. RESTRICT pe FK nu înlocuiește aceste gărzi: schimbarea către o altă ancoră existentă ar reinterpreta istoricul. Numele și bugetul clubului sunt exclusiv în versiuni; contract_version nu duplică player_id/club_id și nu impune season_id.

## Convenții temporale

VT (`valid_from`, `valid_to`) folosește DATE, granularitate de o zi. TT (`tx_from`, `tx_to`) folosește DATETIME(6), microsecunde și UTC. Fiecare tabel de versiuni are CHECK(valid_from < valid_to) și CHECK(tx_from < tx_to). Intervalele sunt semi-deschise [from, to); două intervale adiacente se ating fără suprapunere. BETWEEN nu este potrivit pentru apartenență.

Santinelele sunt exact `9999-12-31` pentru VT și `9999-12-31 23:59:59.999999` pentru TT. Ele indică un capăt deschis convențional și sunt excluse din interval. NULL ar necesita ramuri suplimentare în fiecare predicat. Nu se folosește TIMESTAMP pentru santinele și nici ON UPDATE CURRENT_TIMESTAMP.

```sql
valid_from <= valid_at AND valid_at < valid_to
AND tx_from <= known_at AND known_at < tx_to
```

O versiune curentă în TT are tx_to egal cu santinela; aceasta poate descrie trecutul sau viitorul în VT. „Curent în TT” nu înseamnă „activ astăzi”. Sezoanele de referință, planificate pentru datele finale, sunt 2025/2026 = [2025-07-01, 2026-07-01) și 2026/2027 = [2026-07-01, 2027-07-01). Sunt convenții fictive, iar contractele pot traversa limita de sezon.

Scripturile de scriere folosesc `SET time_zone = '+00:00'`. DATETIME nu convertește automat valorile la UTC. Momentul unei schimbări este capturat o singură dată, din @sim_now valid sau din timpul UTC real în absența sa, apoi înregistrat în tx_registry. Un @sim_now invalid se respinge. @sim_now și tx_registry.tx_time nu pot depăși timpul UTC real, inclusiv când ceasul simulat este furnizat intenționat în viitor. VT viitor este permis; TT efectiv viitor este interzis. Santinela tx_to este excepția convențională pentru un rând deschis.

## Registru, protocol și imutabilitate

O schimbare are un tx_id și un moment comun. Toate inserările sale au tx_from = tx_registry.tx_time, iar închiderile vechilor versiuni folosesc același moment drept tx_to. tx_time nu este unic global: tranzacții diferite pot avea aceeași valoare de timp. tx_event_tag permite mai multe etichete E1–E9 pentru aceeași schimbare, fără dublarea perechii (tx_id, event_code).

Protocolul atomic este blocare ancore → înregistrare schimbare → închidere credințe vechi → inserare credințe noi → verificare → COMMIT; orice eșec cere ROLLBACK. Blocările SELECT ... FOR UPDATE trebuie luate într-o ordine stabilă, inclusiv pentru cluburile părinte, pentru a evita conflicte între verificare și scriere. Un trigger care caută suprapuneri fără serializarea scrierilor nu garantează integritatea în concurență.

Gărzile cerute acceptă numai schimbarea tx_to de la santinelă la un moment strict mai mare decât tx_from și care nu depășește momentul efectiv al scrierii. Pentru coloanele text comparația BINARY respinge inclusiv modificări de majuscule, accente sau spații finale. Ele compară toate celelalte coloane: business, PK, FK, VT, tx_from și tx_id. Sunt respinse UPDATE pe rând închis, redeschiderea, DELETE fizic, INSERT cu tx_from diferit de registru și INSERT al unei versiuni deja închise. Registrul și etichetele înregistrate sunt protejate împotriva rescrierii. Trigger-ele nu încep tranzacții și nu inserează înlocuitori în propriul tabel. Exemplele SQL complete din `docs/write_protocol.md` au fost executate prin `tests/02_write_examples.sql`, cu 37 de aserțiuni reușite.

E3 afirmă tardiv un fapt și păstrează data reală în VT. E4 închide credințele greșite și inserează intervalele corectate, inclusiv fragmentele neafectate. E5 închide în TT și inserează o versiune cu valid_to finit: faptul a încetat în realitate. E8 închide numai TT, fără înlocuitor: afirmația nu a fost niciodată adevărată. E9 reutilizează același tx_id și moment în mai multe tabele. Aceste reguli sunt fundația modelului manual; procedurile automate A1 rămân planificate.

MVCC păstrează versiuni pentru izolarea tranzacțiilor și le poate elimina când nu mai sunt necesare. Nu înlocuiește istoricul de business păstrat explicit și interogabil după cele două ceasuri.

## Integritate și diagnosticul Q0

`v_integrity_violations` este cerut în 01_schema.sql și nu depinde de query_params. Contractul său de ieșire este: invariant_code, source_table, business_key, version_id, conflicting_version_id (nullable), details. source_table separă cheile numeric identice din tabele diferite. Pentru I1/I2, business_key este club_id/contract_id/role_id după sursă; pentru I3 este club_id, inclusiv când source_table este head_coach_role_version; pentru lipsa acoperirii un al doilea version_id poate să nu existe.

| Invariant | Regulă și mecanism |
|---|---|
| I1 | Pe versiuni curente TT, fără suprapuneri VT per club_id / contract_id / role_id; fiecare pereche este comparată o dată, prin version_id ordonat. |
| I2 | VT al contractului și al titularului rolului trebuie acoperit de uniunea VT a versiunilor curente ale clubului, accesat prin ancoră. |
| I3 | Cel mult un titular al poziției pe club la orice dată validă în cunoașterea curentă. Poate coincide cu un diagnostic I1 al role_id. |
| I4 | Istoric imutabil prin gărzi și teste negative; ordinea TT și absența TT efectiv în viitor se verifică separat. |

Suprapunerea este `a.valid_from < b.valid_to AND b.valid_from < a.valid_to`. Pentru I2, reuniunea trebuie calculată inclusiv când părinții se suprapun: insulele pot fi delimitate cu maximul cumulativ al capetelor precedente; un simplu LAG poate eșua pentru intervale imbricate. Copilul trebuie inclus într-o insulă fără pauze. Două intervale părinte adiacente pot acoperi un copil; lipsa totală a părinților, o pauză interioară sau depășirea capetelor trebuie diagnosticate. O sumă brută a duratelor poate ascunde o pauză și nu dovedește acoperirea. Jucătorilor și antrenorilor netemporali nu li se inventează intervale de existență.

I1–I3 sunt diagnosticate de view și respectate de protocol, fără blocaje de INSERT care ar împiedica fixture-urile intenționat invalide. Un Q0 fără rezultate pe o bază goală nu demonstrează corectitudinea implementării. Q0 nu dovedește că istoricul nu a fost modificat anterior; I4 cere gărzi și probe negative separate.

## Parametrii interogărilor

Rândul tehnic inițial cerut este:

| params_id | valid_at | known_at (UTC) | period_start | period_end | subject_id |
|---|---|---|---|---|---|
| 1 | 2026-03-02 | 2026-03-16 12:00:00.000000 | 2025-07-01 | 2026-07-01 | 1 |

PK și CHECK(params_id = 1) permit cel mult un rând; scriptul trebuie să asigure existența lui. Valoarea subject_id = 1 nu dovedește existența unui jucător/club. Q1 o interpretează drept player_id; Q2 și demonstrația Q6 pentru rol drept club_id. Fiecare view viitor trebuie să documenteze interpretarea, iar Q5 nu introduce artificial un filtru de subiect sau VT. Un export numai structural nu păstrează acest rând tehnic.

## Catalogul indexurilor

Numele celor trei indexuri as-of sunt obligatorii. Numele de mai jos sunt corelate prin lectura fișierului 01_schema.sql disponibil la redactare; indexurile as-of sunt verificate automat prin INFORMATION_SCHEMA, iar DDL-ul este păstrat în logul structure.log. Constrângerile primesc prefixe pe tabel: fk_<tabel>_<referință>, ck_<tabel>_<regulă>, uq_<tabel>_<cheie>. Indexul PK este expus ca PRIMARY de motor.

| Tabel | Index / coloane | Utilitate |
|---|---|---|
| player | PRIMARY (player_id) | Identitate și acces direct; unicitate |
| coach | PRIMARY (coach_id) | Identitate și acces direct; unicitate |
| club | PRIMARY (club_id) | Identitate și acces direct; unicitate |
| season | PRIMARY (season_id) | Identitate și acces direct; unicitate |
| contract | PRIMARY (contract_id) | Identitate și acces direct; unicitate |
| head_coach_role | PRIMARY (role_id) | Identitate și acces direct; unicitate |
| club_version | PRIMARY (version_id) | Identitate și acces direct; unicitate |
| contract_version | PRIMARY (version_id) | Identitate și acces direct; unicitate |
| head_coach_role_version | PRIMARY (version_id) | Identitate și acces direct; unicitate |
| tx_registry | PRIMARY (tx_id) | Identitate și acces direct; unicitate |
| tx_event_tag | PRIMARY (tx_id, event_code) | Identitate și acces direct; unicitatea etichetelor și acces FK tx_id |
| query_params | PRIMARY (params_id) | Identitate și acces direct; unicitate |
| player | uq_player_code (player_code) | Cod / nume unic |
| coach | uq_coach_code (coach_code) | Cod / nume unic |
| club | uq_club_code (club_code) | Cod / nume unic |
| season | uq_season_name (season_name) | Cod / nume unic |
| contract | uq_contract_pair (player_id, club_id) | Pereche unică; acces jucător și suport FK player_id |
| contract | ix_contract_club (club_id) | Acces de la club și suport FK |
| head_coach_role | uq_head_coach_role_club (club_id) | O poziție per club și suport FK |
| club_version | ix_club_version_asof (club_id, tx_to, valid_from) | Versiuni ale cheii, curente TT / as-of; suport FK ancoră |
| club_version | ix_club_version_tx (tx_id) | Suport FK și identificarea versiunilor unei schimbări |
| contract_version | ix_contract_version_asof (contract_id, tx_to, valid_from) | Versiuni ale cheii, curente TT / as-of; suport FK ancoră |
| contract_version | ix_contract_version_tx (tx_id) | Suport FK și identificarea versiunilor unei schimbări |
| head_coach_role_version | ix_head_coach_role_version_asof (role_id, tx_to, valid_from) | Versiuni ale cheii, curente TT / as-of; suport FK ancoră |
| head_coach_role_version | ix_head_coach_role_version_tx (tx_id) | Suport FK și identificarea versiunilor unei schimbări |
| head_coach_role_version | ix_head_coach_role_version_coach (coach_id) | Suport FK și acces după titular |

Indexurile UNIQUE și as-of acoperă FK-urile care sunt prefixul lor stâng; nu este necesar un index separat identic pe acel prefix. tx_time rămâne neunic; nu este necesar un index suplimentar în schema minimă. tx_event_tag este acoperit de PK(tx_id, event_code). Nu există index FK pe query_params.subject_id.

Q6 pentru antrenor pornește de la club → rol (index unic club_id) → head_coach_role_version (index as-of). Q6 pentru contract folosește contract_id; un filtru după jucător ajunge prin indexul perechii la ancore. Un B-tree nu rezolvă integral cele două dimensiuni: tx_from, valid_to și unele limite rămân filtre reziduale, iar o condiție de interval poate limita folosirea coloanelor următoare. EXPLAIN cu/fără index pe date reprezentative este planificat; nu există aici câștiguri măsurate.

## Interogările viitoare — toate planificate

| Întrebare | Susținere prin model și semantică |
|---|---|
| Q1 | Contracte ale unui jucător active astăzi și curente TT. |
| Q2 | Rolul clubului, curent TT, cu reunirea perioadelor adiacente ale aceluiași antrenor și duratele mandatului; sfârșitul deschis trebuie explicat la calculul duratei. |
| Q3 | tx_event_tag clasifică E2/E3/E4; diferența TT–VT dă întârzierea. Valorile vechi/noi se asociază pe ancoră și limita comună TT; împărțirile pot produce mai multe rânduri și nu trebuie tratate ca o corespondență arbitrară 1:1. |
| Q4 | „La data V din sezon”: apartenență la punct. „Cândva în sezon”: suprapunere cu sezonul. „Pe tot sezonul”: includere pentru un fapt individual; pentru relația proiectată, acoperire prin uniunea perioadelor curente, fără pauze. |
| Q5 | Toate contractele cu tx_from <= known_at < tx_to, indiferent de VT. |
| Q6 | Cele patru inegalități ale punctului bitemporal; trei momente TT pentru o singură dată VT. |
| Q7 | Calendar explicit / CTE lunar × cluburi, LEFT JOIN la relații curente TT; luni cu zero păstrate. Se va defini dacă se numără activitatea la o dată de referință ori în orice zi a lunii și se evită dublarea aceleiași relații prin versiuni. |
| Q8 | LAG/LEAD pe perioade curente ale aceleiași perechi, după reunire când este necesar; pauzele strict pozitive identifică revenirile. |

## Exemplu didactic — rezultate verificate pe server

Pentru FC Someș, t1 = 2025-07-01 09:00 UTC, t2 = 2026-03-10 14:00 UTC, t3 = 2026-03-15 11:00 UTC. ∞ indică santinela corespunzătoare.

| Rând | Antrenor | VT [from, to) | TT [from, to) |
|---|---|---|---|
| 1 | Ionescu | [2025-07-01, ∞) | [t1, t2) |
| 2 | Ionescu | [2025-07-01, 2026-03-01) | [t2, t3) |
| 3 | Popescu | [2026-03-01, ∞) | [t2, t3) |
| 4 | Ionescu | [2025-07-01, 2026-03-03) | [t3, ∞) |
| 5 | Popescu | [2026-03-03, ∞) | [t3, ∞) |

Pentru valid_at = 2026-03-02, known_at la ora 12:00 UTC în 5, 12 și 16 martie 2026 trebuie să producă Ionescu → Popescu → Ionescu. Sunt trei perspective corecte, nu trei nume distincte. Exact la t2/t3 se selectează numai noua credință. Acesta este un fixture cerut pentru etapa structurală; view-ul final Q6 și demonstrația pe datele finale rămân planificate.

## Limite și pași ulteriori

Diagrama [DOT](../er_diagram.dot) și [PNG](../er_diagram.png) arată PK/FK și cardinalitățile structurale. Regulile intervalelor nu pot fi exprimate numai prin crow's-foot. Matricea [requirements_matrix.md](requirements_matrix.md) separă stadiul documentării de implementare și verificare.

A1 este planificat: proceduri de scriere care gestionează TT și probe negative, peste gărzile cerute acum. A2 este planificat separat: facilitățile native MariaDB și echivalența Q1/Q5/Q6, după verificarea sintaxei pe motorul instalat și a limitelor replay-ului istoric. Compararea cu Oracle, SQL Server și PostgreSQL cerută de raport va folosi cursurile și documentația relevantă la acea etapă. Raportul final de maximum cinci pagini, EXPLAIN și ieșirile interogărilor sunt planificate. Acest dicționar detaliat nu este raportul final.
