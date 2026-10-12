# Protocol de scriere bitemporală

Surse: `docs/references/Assignment1.pdf` (regulile de modelare, E3–E9 și partea D) și `01_schema.sql`. Implementarea este protocolul manual de bază. Triggerele sunt doar gărzi; aceasta nu este implementarea A1, care cere o API de proceduri și interzice scrierea directă a perioadelor TT.

## Ordinea unei scrieri reale

1. Selectează baza extern și folosește UTC: `SET SESSION time_zone = '+00:00'`. Alege izolarea înainte de `START TRANSACTION`.
2. Blochează cu `SELECT ... FOR UPDATE` toate ancorele afectate, inclusiv părinții și ancorele comune operațiilor concurente. Ordinea globală obligatorie este **club → player → coach → contract → head_coach_role**, cu ID crescător în fiecare tabel (`role_id` pentru ultimul). Pentru mai multe ID-uri, achiziția individuală în ordine crescătoare face ordinea explicită. Stabilește întregul set înainte de primul lock; dacă descoperi ulterior un părinte suplimentar, reia tranzacția în ordinea corectă. Păstrează lock-urile până la COMMIT/ROLLBACK.
3. Citește starea curentă după lock-uri. Pentru o ancoră nouă, blochează mai întâi părinții existenți, apoi inserează ancora și capturează imediat `LAST_INSERT_ID()`. Unicitatea perechii contractului și a rolului clubului arbitrează crearea concurentă. Ancorele introduse de propriul INSERT sunt deja protejate; SELECT-urile explicite din exemple arată protocolul. Aceste exemple nu ating coach sau head_coach_role; operațiile cu antrenori trebuie să le includă la pozițiile prescrise.
4. Pentru replay setează `@sim_now` la un datetime UTC canonic, fără fus orar textual, cel mult timpul UTC real. Pentru scriere reală setează `@sim_now = NULL`. Capturează **o singură dată pentru fiecare schimbare logică** `SET @t = fn_effective_time()` după lock-uri. Nu recalcula timpul între rânduri. Timpul trebuie să fie strict ulterior lui `tx_from` pentru fiecare versiune închisă; la egalitate sau la replay în ordine greșită, abandonează și reia corect.
5. Execută `INSERT INTO tx_registry (tx_time, author, reason) VALUES (@t, ..., ...)`, apoi imediat `SET @write_tx_id = LAST_INSERT_ID()`. Inserează toate etichetele în `tx_event_tag` **înaintea versiunilor**.
6. Închide numai versiunile curente vizate: `UPDATE ... SET tx_to = @t ...`. Verifică numărul de rânduri. Nu modifica valoarea business, intervalul valid, `tx_from` sau `tx_id` al vechii versiuni. Pentru înlocuire inserează versiunea cu `tx_from = @t`, `tx_id = @write_tx_id` și `tx_to` sentinel. Pentru E8 nu inserezi înlocuire.
7. Verifică rezultatul business și execută Q0 global: `SELECT * FROM v_integrity_violations`. Trebuie să întoarcă **zero rânduri**. Numai după Q0 zero și toate aserțiunile reușite, scrierea reală poate executa **COMMIT**. Orice eroare, încălcare sau număr neașteptat de rânduri impune **ROLLBACK**. O eroare de statement nu garantează rollback-ul întregii tranzacții.

## Concurență și limitele gărzilor

Exemplele folosesc **READ COMMITTED**: Q0 executat după toate lock-urile și modificările primește un snapshot proaspăt și vede scrierile proprii. Toți writerii trebuie să respecte aceleași ancore și aceeași ordine. De exemplu, închiderea unui club și adăugarea unui contract trebuie să blocheze ambele ancora clubului; verificarea doar a versiunilor existente nu protejează absența unui copil. O modificare a părintelui trebuie să includă ancorele copiilor afectați, citite după blocarea părintelui. Lock-urile rămân deținute și după Q0, până la finalizarea tranzacției.

Alternativ, folosește **SERIALIZABLE**, cu aceleași reguli de lock și cu reluarea întregii tranzacții la deadlock/eșec de serializare. Q0 global poate bloca multe date și poate produce deadlock-uri; aplicația trebuie să le trateze prin rollback și retry. Nu reutiliza pentru Q0 un snapshot vechi din REPEATABLE READ creat înaintea lock-urilor. Un SELECT obișnuit dintr-un asemenea snapshot nu devine proaspăt doar pentru că ai executat ulterior FOR UPDATE. Garanția protocolului presupune că fiecare writer participă; accesul DML arbitrar nu este o API sigură.

`fn_effective_time()` respinge valori simulate invalide, date calendaristice imposibile și valori viitoare. Trigger-ele verifică asocierea cu registrul, deschiderea la sentinel, închiderea strict după deschidere și interzic modificarea istoricului închis, actualizarea coloanelor business și DELETE fizic. Ele pot reciti ceasul pentru validare, dar timestamp-ul scris rămâne exclusiv `@t` capturat de caller. `tx_registry` și `tx_event_tag` sunt imutabile la UPDATE și DELETE; protocolul introduce etichetele înaintea faptelor, însă schema nu interzice adăugarea ulterioară a unei etichete noi prin INSERT. Q0 verifică I1–I3; nu constituie singur o dovadă pentru I4 și nici trigger-ele nu implementează automat toate regulile de concurență.

Intervalele sunt semi-deschise `[from, to)`. Capătul deschis VT este `9999-12-31`, iar TT este `9999-12-31 23:59:59.999999`. Închiderea păstrează `tx_id` al vechii afirmații; `@write_tx_id` identifică operația care o închide și eventualele înlocuiri.

## Ce demonstrează exemplele

| Exemplu | Rezultat afirmat automat |
| --- | --- |
| E3 | Contract valabil din 31 ianuarie, introdus pe 10 februarie: întârziere de 10 zile; absent din cunoașterea de pe 5 februarie. |
| E4 | Salariul greșit 1000 este corectat la 1500 de la începutul aceluiași interval valid; vechea valoare rămâne interogabilă înaintea corecției. |
| E5 | Plecare reală pe 1 februarie: înlocuire cu valid_to finit; contractul este în continuare adevărat pentru 31 ianuarie, dar nu și la limita 1 februarie. |
| E8 | Contractul nu a existat niciodată: închidere doar în TT, fără înlocuire; nicio perioadă contractuală nu mai este acceptată în cunoașterea curentă, însă credința veche rămâne în istoric. |
| E9 | O singură decizie corectează salariul și bugetul; contract_version și club_version au exact același tx_id și tx_from, egale cu registrul. |

E5 păstrează adevărul trecut în starea curentă; E8 retrage întregul fapt din starea curentă. Fiecare bloc construiește propriul fixture E1 și schimbarea demonstrată, cu câte un registru și un timestamp per schimbare logică, în interiorul aceleiași tranzacții fizice de test. ID-urile ancorelor, registrului și versiunilor sunt capturate imediat cu LAST_INSERT_ID; nu există dependență de ID-uri fixe sau de celelalte exemple. Codurile unice folosesc UUID. Nu sunt acoperite aici volumele minime ale timeline-ului ori suita de teste negative.

## Rulare și aserțiuni

Fișierul canonic pentru execuție este `tests/02_write_examples.sql`; blocul de mai jos este copiat integral din el, fără adaptări. **SQL executat cu succes pe MariaDB 11.8.8**: 37 de aserțiuni; probele și logurile sunt în `verification/summary.md`.

Rulează după `01_schema.sql`, într-o bază de test cu Q0 inițial gol și CHECK-uri active, folosind client MariaDB/MySQL în mod batch care se oprește la prima eroare, fără `--force`. Fiecare secțiune BEGIN E3/E4/E5/E8/E9 se poate extrage și rula separat. Nu porni dintr-o tranzacție deja activă. Sesiunea rămâne configurată UTC și READ COMMITTED; închide conexiunea de test la final.

Tabelul temporar cu `CHECK (ok = 1)` transformă orice aserțiune falsă sau NULL în eroare SQL, inclusiv Q0 nenul. Un SELECT afișează numele aserțiunilor reușite. Nu sunt necesare proceduri, privilegii CREATE ROUTINE sau modificări ale schemei persistente; este necesar privilegiul CREATE TEMPORARY TABLES. DROP TEMPORARY TABLE nu face COMMIT implicit. La eroare execută ROLLBACK și închide conexiunea pentru eliminarea tabelului temporar; nu continua cu următorul exemplu în aceeași sesiune contaminată.

Fiecare exemplu se termină cu **ROLLBACK**, astfel încât toate ancorele, registrele, etichetele și versiunile sale dispar; contoarele AUTO_INCREMENT pot rămâne avansate. Pentru o scriere reală, aplică protocolul datelor reale și încheie cu COMMIT numai după Q0 zero și verificările business, fără fixture-ul demonstrativ. Nu înlocui mecanic ROLLBACK cu COMMIT în fișierul de teste.

## SQL canonic, integral

```sql
-- Run with a MariaDB/MySQL client that stops on SQL error; do not use --force.
-- Requires 01_schema.sql and enforced CHECK constraints. Select the database externally.
-- On any error: ROLLBACK, then close the connection (temporary table cleanup).
-- Each section is standalone; all persistent fixture/change rows are rolled back.

-- BEGIN E3: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E3 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Late contract entered ten days after January 31');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E3');

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-31', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-31' AND valid_to = '9999-12-31' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: late by ten days and absent before recording', COALESCE((DATEDIFF(@t, '2025-01-31') = 10 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to) = 0), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E3') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E3: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E4: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E4 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Correct erroneous salary from inception');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E4');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1500, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1500 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E4') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E4: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E5: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E5 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Player really left on February 1');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E5');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '2025-02-01', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '2025-02-01' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: real tenure remains; departure boundary excluded', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf AND valid_from <= '2025-01-31' AND '2025-01-31' < valid_to) = 1 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf AND valid_from <= '2025-02-01' AND '2025-02-01' < valid_to) = 0), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E5') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E5: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E8: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E8 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'Retract contract that never existed');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E8');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: no replacement; past tenure also retracted', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id) = 1 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 0 AND (SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_id = @write_tx_id) = 0), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E8') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E8: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;

-- BEGIN E9: independent fixture + logical change.
SET SESSION time_zone = '+00:00';
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Temporary CHECK table turns false/NULL assertions into SQL errors.
CREATE TEMPORARY TABLE tc_write_example_assert (
  assertion_name VARCHAR(120) NOT NULL PRIMARY KEY,
  ok TINYINT NOT NULL CHECK (ok = 1)
) ENGINE=InnoDB;
START TRANSACTION;
SET @inf = '9999-12-31 23:59:59.999999';
SET @suffix = REPLACE(UUID(), '-', '');
-- Anchors created/locked in global order: club, player, coach, contract, role.
INSERT INTO club (club_code) VALUES (CONCAT('WX', LEFT(@suffix, 30)));
SET @club_id = LAST_INSERT_ID();
SELECT club_id FROM club WHERE club_id = @club_id ORDER BY club_id FOR UPDATE;
INSERT INTO player (player_code, full_name, birth_date)
VALUES (CONCAT('WX', LEFT(@suffix, 30)), 'Write example player', '2000-01-01');
SET @player_id = LAST_INSERT_ID();
SELECT player_id FROM player WHERE player_id = @player_id ORDER BY player_id FOR UPDATE;
-- No coach or head_coach_role is involved in these contract/budget examples.
INSERT INTO contract (player_id, club_id) VALUES (@player_id, @club_id);
SET @contract_id = LAST_INSERT_ID();
SELECT contract_id FROM contract WHERE contract_id = @contract_id ORDER BY contract_id FOR UPDATE;

SET @sim_now = '2025-01-02 09:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'E9 initial fixture');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E1');

SET @fixture_tx_id = @write_tx_id;
SET @fixture_t = @t;
INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1000000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @old_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: Q0 fixture is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SET @sim_now = '2025-02-10 12:00:00.000000';
SET @t = fn_effective_time();
INSERT INTO tx_registry (tx_time, author, reason)
VALUES (@t, 'write_protocol', 'One decision adjusts contract salary and club budget');
SET @write_tx_id = LAST_INSERT_ID();
INSERT INTO tx_event_tag (tx_id, event_code) VALUES (@write_tx_id, 'E9');

UPDATE contract_version SET tx_to = @t
WHERE version_id = @old_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: exactly one old contract closed', COALESCE((@closed_count = 1), 0);

UPDATE club_version SET tx_to = @t
WHERE version_id = @old_club_version_id AND tx_to = @inf;
SET @closed_count = ROW_COUNT();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: exactly one old club closed', COALESCE((@closed_count = 1), 0);

INSERT INTO club_version (club_id, club_name, budget_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@club_id, 'Write example club', 1200000, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_club_version_id = LAST_INSERT_ID();

INSERT INTO contract_version (contract_id, agreement_kind, salary_eur, valid_from, valid_to, tx_from, tx_to, tx_id)
VALUES (@contract_id, 'PERMANENT', 1500, '2025-01-01', '9999-12-31', @t, @inf, @write_tx_id);
SET @new_version_id = LAST_INSERT_ID();

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: one expected current contract', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND tx_to = @inf) = 1 AND
 (SELECT COUNT(*) FROM contract_version WHERE version_id = @new_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1500 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @t AND tx_to = @inf AND tx_id = @write_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: old belief preserved exactly', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE version_id = @old_version_id AND contract_id = @contract_id AND agreement_kind = 'PERMANENT' AND salary_eur = 1000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: old salary visible before change', COALESCE(((SELECT COUNT(*) FROM contract_version WHERE contract_id = @contract_id AND valid_from <= '2025-01-15' AND '2025-01-15' < valid_to AND tx_from <= '2025-02-05 12:00:00' AND '2025-02-05 12:00:00' < tx_to AND salary_eur = 1000) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: same tx_id and timestamp in two tables', COALESCE(((SELECT COUNT(*) FROM contract_version c JOIN club_version b ON b.tx_id = c.tx_id AND b.tx_from = c.tx_from JOIN tx_registry r ON r.tx_id = c.tx_id AND r.tx_time = c.tx_from WHERE c.version_id = @new_version_id AND b.version_id = @new_club_version_id AND c.tx_id = @write_tx_id AND c.tx_from = @t AND c.salary_eur = 1500 AND b.budget_eur = 1200000 AND c.tx_to = @inf AND b.tx_to = @inf) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: old budget preserved', COALESCE(((SELECT COUNT(*) FROM club_version WHERE version_id = @old_club_version_id AND budget_eur = 1000000 AND valid_from = '2025-01-01' AND valid_to = '9999-12-31' AND tx_from = @fixture_t AND tx_to = @t AND tx_id = @fixture_tx_id) = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: event tag and registered timestamp', COALESCE(((SELECT COUNT(*) FROM tx_registry r JOIN tx_event_tag e ON e.tx_id = r.tx_id WHERE r.tx_id = @write_tx_id AND r.tx_time = @t AND e.event_code = 'E9') = 1), 0);

INSERT INTO tc_write_example_assert (assertion_name, ok)
SELECT 'E9: Q0 final is empty', COALESCE(((SELECT COUNT(*) FROM v_integrity_violations) = 0), 0);

SELECT assertion_name, ok FROM tc_write_example_assert ORDER BY assertion_name;
-- DROP TEMPORARY TABLE does not implicitly commit. No persistent DDL in this test.
DROP TEMPORARY TABLE tc_write_example_assert;
SET @sim_now = NULL;
SET @write_tx_id = NULL;
ROLLBACK;
```
