-- Silver layer: cleaned and typed data
CREATE SCHEMA IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.superstore_clean;

CREATE TABLE silver.superstore_clean (
    row_id          INTEGER PRIMARY KEY,
    order_id        TEXT NOT NULL,
    order_date      DATE NOT NULL,
    ship_date       DATE NOT NULL,
    ship_mode       TEXT,
    customer_id     TEXT NOT NULL,
    customer_id_original TEXT,
    customer_name   TEXT,
    segment         TEXT,
    city            TEXT,
    state           TEXT,
    country         TEXT,
    postal_code     TEXT,
    market          TEXT,
    region          TEXT,
    product_id      TEXT NOT NULL,
    category        TEXT,
    sub_category    TEXT,
    product_name    TEXT NOT NULL,
    sales           NUMERIC(14,5) NOT NULL,
    quantity        INTEGER NOT NULL,
    discount        NUMERIC(5,3) NOT NULL,
    profit          NUMERIC(14,5) NOT NULL,
    shipping_cost   NUMERIC(10,2) NOT NULL,
    order_priority  TEXT,
    loaded_at       TIMESTAMP DEFAULT NOW()
);