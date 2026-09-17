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

The fourth command prints **2 rows**; both must show `PASS` in the result column:

- **`row_count = 51290`** — exactly 51,290 data rows landed; 51,291 would mean the header row loaded as data.
- **`column_count = 26`** — the table has the 24 source columns plus the 2 audit columns.

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

## 11. Build and verify the cleansed layer

Run the cleansed files in order, reading each result before continuing:

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/20_cleansed/01_drop_views.sql
```
Expected: `DROP VIEW` three times (or a NOTICE "does not exist, skipping" on a fresh database)

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/20_cleansed/02_create_sales_checked.sql
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/20_cleansed/03_create_sales.sql
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/20_cleansed/04_create_dq_rejects.sql
```
Expected: `CREATE VIEW` each time

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/20_cleansed/05_verify_cleansed.sql
```
Expected scorecard:

```
staging_rows                  | 51290
clean_rows                    | 51290
rejected_rows                 | 0
every_row_accounted_for       | t
sales_values_unchanged        | t
profit_values_unchanged       | t
postal_codes_not_5_characters | 0
product_names_with_odd_spaces | 0
product_names_untrimmed       | 0
expected_country_dim_rows     | 152
expected_customer_dim_rows    | 1590
expected_product_dim_rows     | 10768
```

followed by an empty reject list: `(0 rows)`. `every_row_accounted_for = t` means every staging row is either clean or rejected — none lost, none duplicated.

## 12. Prove the reject rules work

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/20_cleansed/06_test_rejects.sql
```

This inserts 5 deliberately bad rows inside a transaction and rolls back. Expected:

```
 source_row_id |                    reject_reason
---------------+------------------------------------------------------
 900001        | order_date is missing or not a real DD-MM-YYYY date
 900002        | quantity is zero or negative
 900003        | sales is missing or not a number
 900004        | a required field is missing
 900005        | shipped before it was ordered
(5 rows)

 staging_rows_during_test | clean_rows_during_test | rejected_rows_during_test
--------------------------+------------------------+---------------------------
                    51295 |                  51290 |                         5
(1 row)

ROLLBACK
```

Then confirm the rollback left nothing behind:

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -c "select count(*) from stg.sales_raw;"
```
Expected: `51290`

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -c "select count(*) from cleansed.dq_rejects;"
```
Expected: `0`

## 13. Check the target structure

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -v ON_ERROR_STOP=1 -f /sql/30_dwh/05_verify_structure.sql
```

Expected scorecard (the tables are created empty — Chapter 4 loads them):

```
tables_in_dwh     | 4
primary_keys      | 4
business_keys     | 4
foreign_keys      | 3
identity_columns  | 4
country_dim_rows  | 0
customer_dim_rows | 0
product_dim_rows  | 0
fact_rows         | 0
```

followed by the constraint list — exactly 11 rows: 4 PRIMARY KEY, 4 UNIQUE (the
business keys) and 3 FOREIGN KEY on the fact.

## 14. Prove the target rules work

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -f /sql/30_dwh/06_test_constraints.sql
```

This deliberately fires four errors inside a transaction and rolls everything
back. Expected errors:

- `duplicate key value violates unique constraint "country_dim_business_key"`
- `cannot insert a non-DEFAULT value into column "country_key"`
- `insert or update on table "sales_transactions_fact" violates foreign key constraint "sales_transactions_fact_country_fk"`
- `null value in column "customer_name" of relation "customer_dim" violates not-null constraint`

Note that the ERROR lines may appear slightly out of order relative to the
`ROLLBACK` lines in the terminal, because errors and normal output are printed
through different streams.

Then confirm nothing was left behind:

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -c "select count(*) from dwh.country_dim;"
```
Expected: `0`

## 15. Connect from a GUI client

In DBeaver or pgAdmin, create a connection with: host `localhost`, port `5433`, database `superstore_dwh`, user `postgres`, password `postgres`. Browse to `stg.sales_raw` and confirm you see 51,290 rows.

## 16. Test the reset

```bash
docker compose down -v
docker compose up -d --wait
docker compose exec db psql -U postgres -d superstore_dwh -c "\dt stg.*"
```

Correct output of the last command: `Did not find any relations.` — the database is empty again.

Then re-run the runner:

```bash
python sql/run_all.py
```

and confirm the staging verification shows both checks PASS again.

## 17. Shut down

```bash
docker compose down
```

This stops the container but keeps the data volume, so your loaded rows survive the next `docker compose up -d --wait`.

---

## Optional: prove the encoding check isn't lying

1. Open `sql/10_stg/02_load_sales_raw.sql` and temporarily change `encoding 'WIN1252'` to `encoding 'LATIN1'`.
2. Re-run the load file (`/sql/10_stg/01_create_sales_raw.sql` then `/sql/10_stg/02_load_sales_raw.sql`).
3. Run:

```bash
docker compose exec -T db psql -U postgres -d superstore_dwh -c "select count(*) from stg.sales_raw where product_name ~ ('[' || chr(128) || '-' || chr(159) || ']');"
```

Expected with LATIN1: **43** (invisible C1 control characters). Change the file back to `'WIN1252'`, re-run, and the same query returns **0**.

Note that the load reports `COPY 51290` success **both times** — that silent corruption is exactly what the check exists to catch. (43 and 0 were measured against this dataset.)

## Troubleshooting

- **`docker compose` not found inside the runner** — upgrade to a recent Docker Desktop (Compose v2 ships built in).
- **Port 5433 already in use** — set `HOST_PORT` in `.env` (e.g. `HOST_PORT=5434`) and run `docker compose up -d` again.
- **"Cannot connect to the Docker daemon"** — Docker Desktop is not running. Start it and wait for it to be ready.
- **Changed `POSTGRES_DB` but the new database does not appear** — `POSTGRES_DB` only takes effect on a fresh volume. Run `docker compose down -v` first, then `docker compose up -d --wait`.
- **"cannot drop table stg.sales_raw because other objects depend on it"** — the cleansed views exist. Run `sql/20_cleansed/01_drop_views.sql` first, or just use `run_all.py`, which drops them for you before rebuilding staging.
