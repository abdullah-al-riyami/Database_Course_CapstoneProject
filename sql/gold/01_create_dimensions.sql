-- Gold layer: dimension tables for the star schema
CREATE SCHEMA IF NOT EXISTS gold;

-- Customer: one row per customer_id
DROP TABLE IF EXISTS gold.dim_customer CASCADE;
CREATE TABLE gold.dim_customer (
    customer_key   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id    TEXT NOT NULL UNIQUE,
    customer_name  TEXT,
    segment        TEXT
);

-- Product: one row per product_id + product_name (Check 5)
DROP TABLE IF EXISTS gold.dim_product CASCADE;
CREATE TABLE gold.dim_product (
    product_key    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id     TEXT NOT NULL,
    product_name   TEXT NOT NULL,
    category       TEXT,
    sub_category   TEXT,
    UNIQUE (product_id, product_name)
);

-- Location: one row per delivery place (Check 7)
DROP TABLE IF EXISTS gold.dim_location CASCADE;
CREATE TABLE gold.dim_location (
    location_key   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city           TEXT NOT NULL,
    state          TEXT NOT NULL,
    country        TEXT NOT NULL,
    postal_code    TEXT,
    region         TEXT NOT NULL,
    market         TEXT NOT NULL,
    UNIQUE NULLS NOT DISTINCT (city, state, country, postal_code, region, market)
);

-- Date: one row per calendar day
DROP TABLE IF EXISTS gold.dim_date CASCADE;
CREATE TABLE gold.dim_date (
    date_key      INTEGER PRIMARY KEY,      -- e.g. 20140315
    full_date     DATE NOT NULL UNIQUE,
    year          INTEGER,
    quarter       INTEGER,
    month         INTEGER,
    month_name    TEXT,
    day_of_month  INTEGER,
    day_name      TEXT,
    is_weekend    BOOLEAN
);