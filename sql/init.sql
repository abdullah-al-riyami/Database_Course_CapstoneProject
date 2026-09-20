-- Bronze (stage) layer
\i /docker-entrypoint-initdb.d/bronze/01_create_stage.sql
\i /docker-entrypoint-initdb.d/bronze/02_load_stage.sql

-- Control layer
\i /docker-entrypoint-initdb.d/control/01_create_control.sql

-- Run the bronze load, then plant the duplicates
CALL stage.load_stage();
\i /docker-entrypoint-initdb.d/bronze/03_inject_test_duplicates.sql

-- Silver layer
\i /docker-entrypoint-initdb.d/silver/01_create_silver.sql
\i /docker-entrypoint-initdb.d/silver/02_load_silver.sql

-- Run the silver load
CALL silver.load_silver();

-- Gold layer
\i /docker-entrypoint-initdb.d/gold/01_create_dimensions.sql
\i /docker-entrypoint-initdb.d/gold/02_create_fact.sql
\i /docker-entrypoint-initdb.d/gold/03_load_dim_customer.sql
\i /docker-entrypoint-initdb.d/gold/04_load_dim_product.sql
\i /docker-entrypoint-initdb.d/gold/05_load_dim_location.sql
\i /docker-entrypoint-initdb.d/gold/06_load_dim_date.sql
\i /docker-entrypoint-initdb.d/gold/07_load_fact_sales.sql

-- Run the gold loads: dimensions first, fact last
CALL gold.load_dim_customer();
CALL gold.load_dim_product();
CALL gold.load_dim_location();
CALL gold.load_dim_date();
CALL gold.load_fact_sales();