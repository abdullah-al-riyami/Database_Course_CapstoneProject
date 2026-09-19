-- Bronze layer: raw data exactly as it arrives from the CSV
CREATE SCHEMA IF NOT EXISTS stage;

DROP TABLE IF EXISTS stage.superstore_raw;

CREATE TABLE stage.superstore_raw (
    row_id          TEXT,
    order_id        TEXT,
    order_date      TEXT,
    ship_date       TEXT,
    ship_mode       TEXT,
    customer_id     TEXT,
    customer_name   TEXT,
    segment         TEXT,
    city            TEXT,
    state           TEXT,
    country         TEXT,
    postal_code     TEXT,
    market          TEXT,
    region          TEXT,
    product_id      TEXT,
    category        TEXT,
    sub_category    TEXT,
    product_name    TEXT,
    sales           TEXT,
    quantity        TEXT,
    discount        TEXT,
    profit          TEXT,
    shipping_cost   TEXT,
    order_priority  TEXT
);