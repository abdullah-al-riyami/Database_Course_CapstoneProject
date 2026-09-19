-- Procedure: clean the stage data into silver and log the run
CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id       INTEGER;
    v_rows_read    INTEGER;
    v_rows_loaded  INTEGER;
    v_error        TEXT;
BEGIN
    -- Part 1: log the start
    INSERT INTO control.etl_run_log (process_name, layer)
    VALUES ('load_silver', 'silver')
    RETURNING run_id INTO v_run_id;
    COMMIT;

    -- Part 2: do the load
    BEGIN
        -- How many rows are we starting with?
        SELECT COUNT(*) INTO v_rows_read FROM stage.superstore_raw;

        TRUNCATE TABLE silver.superstore_clean;

        -- Number the copies of each row_id; keep only the first (removes duplicates)
        WITH ranked AS (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY row_id ORDER BY row_id) AS rn
            FROM stage.superstore_raw
        )
        INSERT INTO silver.superstore_clean (
            row_id, order_id, order_date, ship_date, ship_mode,
            customer_id, customer_name, segment,
            city, state, country, postal_code, market, region,
            product_id, category, sub_category, product_name,
            sales, quantity, discount, profit, shipping_cost, order_priority
        )
        SELECT
            TRIM(row_id)::INTEGER,
            TRIM(order_id),
            TO_DATE(TRIM(order_date), 'DD-MM-YYYY'),   -- text to real date (Check 3)
            TO_DATE(TRIM(ship_date),  'DD-MM-YYYY'),
            TRIM(ship_mode),
            TRIM(customer_id),
            TRIM(customer_name),
            TRIM(segment),
            TRIM(city),
            TRIM(state),
            TRIM(country),
            CASE                                        -- restore leading zero on US postal codes (Check 4)
                WHEN TRIM(country) = 'United States' AND LENGTH(TRIM(postal_code)) = 4
                    THEN LPAD(TRIM(postal_code), 5, '0')
                ELSE NULLIF(TRIM(postal_code), '')      -- blanks become NULL (Check 2)
            END,
            TRIM(market),
            TRIM(region),
            TRIM(product_id),
            TRIM(category),
            TRIM(sub_category),
            TRIM(product_name),
            TRIM(sales)::NUMERIC,
            TRIM(quantity)::INTEGER,
            TRIM(discount)::NUMERIC,
            TRIM(profit)::NUMERIC,
            TRIM(shipping_cost)::NUMERIC,
            TRIM(order_priority)
        FROM ranked
        WHERE rn = 1;

        -- How many rows did the INSERT just add?
        GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

        -- Part 3a: log success
        UPDATE control.etl_run_log
        SET end_time    = clock_timestamp(),
            status      = 'SUCCESS',
            rows_read   = v_rows_read,
            rows_loaded = v_rows_loaded
        WHERE run_id = v_run_id;

    EXCEPTION WHEN OTHERS THEN
        -- Part 3b: log failure
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;

        UPDATE control.etl_run_log
        SET end_time      = clock_timestamp(),
            status        = 'FAILED',
            rows_read     = v_rows_read,
            error_message = v_error
        WHERE run_id = v_run_id;

        RAISE WARNING 'load_silver failed: %', v_error;
    END;

    COMMIT;
END;
$$;