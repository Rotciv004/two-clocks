# Reconstrucție și export — etapa 2

Mecanismul academic este rularea fișierelor materializate `01_schema.sql`, `02_data.sql`, `03_timeline.sql` în această ordine, într-o **bază nouă**. Nu este necesar Python pentru aceste trei scripturi SQL. Runnerul Python este doar orchestrarea verificărilor, logurilor și comparațiilor.

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/verify_dataset.sh"
```

Runnerul creează două baze cu nume noi, selectează explicit schema din client, confirmă `DATABASE()`, apoi execută 01 → 02 → 03 și verificările. Nu resetează baze existente. Pe a doua bază rulează înainte testele etapei 1, cu ROLLBACK, astfel încât ID-urile surrogate avansează natural. Comparația replay-urilor se face pe coduri și perioade, nu pe ID-uri.

Echivalent manual, folosind o conexiune administrativă deja autorizată, într-un terminal local:

```bash
CABD_PROJECT_ROOT='/home/RotcivRaob/Data/Documents/Facultate/Master/Anul 1/SEM I/CABD/PROJECTS/Two Clocks'
CABD_REPLAY_DB="two_clocks_cabd_replay_$(date -u +%Y%m%d_%H%M%S)_${RANDOM}"
pkexec /usr/bin/mariadb --batch -e "CREATE DATABASE \`$CABD_REPLAY_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
pkexec /usr/bin/mariadb --batch --database="$CABD_REPLAY_DB" -e 'SELECT DATABASE();'
pkexec /usr/bin/mariadb --batch --database="$CABD_REPLAY_DB" < "$CABD_PROJECT_ROOT/01_schema.sql"
pkexec /usr/bin/mariadb --batch --database="$CABD_REPLAY_DB" < "$CABD_PROJECT_ROOT/02_data.sql"
pkexec /usr/bin/mariadb --batch --database="$CABD_REPLAY_DB" < "$CABD_PROJECT_ROOT/03_timeline.sql"
pkexec /usr/bin/mariadb --batch --database="$CABD_REPLAY_DB" < "$CABD_PROJECT_ROOT/tests/03_dataset_assertions.sql"
```

Oprește la prima comandă nereușită; pentru automatizare folosește runnerul cu fail-fast. **01 recreează obiectele**; nu îl executa asupra principalei populate. 02 refuză date existente, iar 03 cere prefixul exact la fiecare eveniment. După un eșec nu relansa 03 peste prefixul comis: logul indică evenimentul eșuat și ultimul Tnn comis. Reconstruiește într-o bază nouă sau proiectează o reluare explicită, verificată; nu șterge istoricul.

## Backup și dump complet

`scripts/populate_main.sh` cere mai întâi verificarea reușită a acelorași checksum-uri. Înainte de prima scriere produce `exports/two_clocks_cabd_before_phase2_<timestamp>.sql`. După verificare produce `exports/two_clocks_cabd_phase2.sql` cu `mariadb-dump --single-transaction --routines --triggers --hex-blob`, **cu date**. Checksum-urile sunt în manifestul rulării. Exportul structural anterior `exports/schema_only.sql` este păstrat.

```bash
pkexec /usr/bin/bash "$CABD_PROJECT_ROOT/scripts/populate_main.sh"
```

O bază principală deja identică este verificată și raportată `ALREADY POPULATED`, fără replay. Datele parțiale sau necunoscute sunt păstrate și opresc scriptul. Nicio resetare automată a principalei.

## Limita restaurării native

Dump-ul complet este un export real. Verificarea efectivă a reconstrucției este **replay-ul 01 → 02 → 03**, nu o restaurare nativă a acestui dump. Nu confunda exportarea cu restaurarea testată.

Dump-ul trebuie inspectat pentru CREATE DATABASE, USE, DEFINER și calificatorii view-urilor înainte de restaurarea într-o clonă. MariaDB poate exporta Q0 cu referințe la schema originală. Înlocuiește numai calificatorii din DDL-ul identificat al view-ului pentru o clonă și verifică `SHOW CREATE VIEW` acolo; nu înlocui global șiruri din datele istorice. În acest proiect, metoda verificată pe alt nume de bază este replay-ul, care nu conține USE fix sau calificatori către principală.

Un import nativ poate încărca rânduri înainte de recrearea trigger-elor conform ordinii dump-ului. Aceasta nu autorizează dezactivarea protecțiilor în replay sau în baza principală. Toate replay-urile proiectului rulează cu trigger-ele active.
