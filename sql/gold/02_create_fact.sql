-- Gold layer: fact table, one row per sales line (row_id)
DROP TABLE IF EXISTS gold.fact_sales;

CREATE TABLE gold.fact_sales (
    sales_key       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    row_id          INTEGER NOT NULL UNIQUE,
    order_id        TEXT    NOT NULL,

    -- Keys to the dimensions
    order_date_key  INTEGER NOT NULL REFERENCES gold.dim_date (date_key),
    ship_date_key   INTEGER NOT NULL REFERENCES gold.dim_date (date_key),
    customer_key    INTEGER NOT NULL REFERENCES gold.dim_customer (customer_key),
    product_key     INTEGER NOT NULL REFERENCES gold.dim_product (product_key),
    location_key    INTEGER NOT NULL REFERENCES gold.dim_location (location_key),

    -- Descriptive details of the sale
    ship_mode       TEXT,
    order_priority  TEXT,

    -- Measures
    sales           NUMERIC(14,5) NOT NULL,
    quantity        INTEGER       NOT NULL,
    discount        NUMERIC(5,3)  NOT NULL,
    profit          NUMERIC(14,5) NOT NULL,
    shipping_cost   NUMERIC(10,2) NOT NULL
);