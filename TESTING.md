# Testing walkthrough

Follow these steps in order, from the project root (`Database_Project/`). Each step gives the exact command and what correct output looks like.

## 1. Confirm Docker is installed and running

```bash
docker --version
docker compose version
```

Correct output looks like:

```
Docker version 27.x.x, build xxxxxxx
Docker Compose version v2.x.x
```

If `docker --version` fails: Docker Desktop is not installed. If either command prints "Cannot connect to the Docker daemon": Docker Desktop is installed but not running — start it.

## 2. Start the database

```bash
docker compose up -d --wait
```

Correct output ends with:

```
 ✔ Container superstore_db  Healthy
```

`--wait` blocks until the healthcheck passes, so the database is genuinely ready — not just started — before you continue.

## 3. Confirm the container is healthy

```bash
docker compose ps
```

Correct output:

```
NAME            SERVICE   STATUS
superstore_db   db        Up ... (healthy)
```

Status must say **healthy**.

## 4. Confirm the CSV is visible inside the container

```bash
docker compose exec db ls -lh /data
```

Correct output:

```
-rwxr-xr-x 1 root root 12M ... Global_Superstore2.csv
```

Expect `Global_Superstore2.csv`, about 12 MB.

## 5. Confirm the dataset mount is genuinely read-only

```bash
docker compose exec db touch /data/should_fail.txt
```

Correct output is an **error**:

```
touch: cannot touch '/data/should_fail.txt': Read-only file system
```

This failing IS the passing result. It proves the container physically cannot modify the source dataset.

## 6. Confirm the SQL files are visible

```bash
docker compose exec db ls /sql/10_stg
```

Correct output:

```
01_create_sales_raw.sql
02_load_sales_raw.sql
03_verify_load.sql
```

## 7. Connect manually

```bash
docker compose exec db psql -U postgres -d superstore_dwh -c "select version();"
```

Correct output starts with:

```
PostgreSQL 17.x ...
```

## 8. Run each SQL file, one at a time

Run these in order, reading each result before continuing:

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/00_setup/01_create_schemas.sql
```
Expected: `CREATE SCHEMA`

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/10_stg/01_create_sales_raw.sql
```
Expected: `DROP TABLE` then `CREATE TABLE`

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/10_stg/02_load_sales_raw.sql
```
Expected: `TRUNCATE TABLE` then `COPY 51290`

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/10_stg/03_verify_load.sql
```

`COPY 51290` is the critical number in the third command: exactly 51,290 data rows landed. 51,291 would mean the header row was loaded as data.

## 9. Read the verification output

The fourth command prints **13 rows**; every one must show `PASS` in the result column.

Two rows deserve special attention:

- **`distinct_order_priority = 4`** proves the CSV parsed correctly. `order_priority` is the last column of the file, so a comma inside a quoted product name that was mis-parsed would shift fields and inflate this count far past 4.
- **`product_name_smart_quotes = 43` together with `c1_control_chars = 0`** proves the WIN1252 encoding was applied. If you see 0 smart quotes and 43 control chars instead, the file silently loaded as LATIN1 — the load "succeeds" but the data is corrupted.

## 10. Spot-check the data by hand

```bash
docker compose exec db psql -U postgres -d superstore_dwh -c "select country, count(*) from stg.sales_raw group by 1 order by 2 desc limit 5;"
```

Correct output (United States on top by a wide margin):

```
    country    | count
---------------+-------
 United States |  9994
 Australia     |  2837
 France        |  2827
 Mexico        |  2644
 Germany       |  2065
(5 rows)
```

## 11. Connect from a GUI client

In DBeaver or pgAdmin, create a connection with: host `localhost`, port `5433`, database `superstore_dwh`, user `postgres`, password `postgres`. Browse to `stg.sales_raw` and confirm you see 51,290 rows.

## 12. Test the reset

```bash
docker compose down -v
docker compose up -d --wait
docker compose exec db psql -U postgres -d superstore_dwh -c "\dt stg.*"
```

Correct output of the last command: `Did not find any relations.` — the database is empty again.

Then re-run the runner:

```bash
python sql/run_stg.py
```

and confirm all 13 checks pass again.

## 13. Shut down

```bash
docker compose down
```

This stops the container but keeps the data volume, so your loaded rows survive the next `docker compose up -d --wait`.

---

## Optional: prove the checks aren't lying

The verification checks are only useful if they actually catch problems. Prove it to yourself:

1. Open `sql/10_stg/02_load_sales_raw.sql` and temporarily change `encoding 'WIN1252'` to `encoding 'LATIN1'`.
2. Re-run steps 8 and 9 (the load must run again: repeat the `01_create_sales_raw.sql` file too, or just `truncate` first).
3. Observe the result: `product_name_smart_quotes` becomes **0** and `c1_control_chars` becomes **43** — two FAIL rows, while the overall load still "succeeds".
4. Change the file back to `'WIN1252'` and re-run to restore 43 / 0.

This demonstrates a load that completes without errors yet contains silently corrupted text — exactly the class of failure these checks exist to catch.

## Troubleshooting

- **`docker compose` not found inside the runner** — upgrade to a recent Docker Desktop (Compose v2 ships built in).
- **Port 5433 already in use** — set `HOST_PORT` in `.env` (e.g. `HOST_PORT=5434`) and run `docker compose up -d` again.
- **"Cannot connect to the Docker daemon"** — Docker Desktop is not running. Start it and wait for it to be ready.
- **Changed `POSTGRES_DB` but the new database does not appear** — `POSTGRES_DB` only takes effect on a fresh volume. Run `docker compose down -v` first, then `docker compose up -d --wait`.
