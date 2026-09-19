-- Procedure: load dim_customer from silver and log the run
CREATE OR REPLACE PROCEDURE gold.load_dim_customer()
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
    VALUES ('load_dim_customer', 'gold')
    RETURNING run_id INTO v_run_id;
    COMMIT;

    -- Part 2: do the load
    BEGIN
        SELECT COUNT(*) INTO v_rows_read FROM silver.superstore_clean;

        -- Empty the table and restart the key numbering at 1
        TRUNCATE TABLE gold.dim_customer RESTART IDENTITY CASCADE;

        -- One row per customer, using the details from their latest order
        INSERT INTO gold.dim_customer (customer_id, customer_name, segment)
        SELECT customer_id, customer_name, segment
        FROM (
            SELECT customer_id, customer_name, segment,
                   ROW_NUMBER() OVER (PARTITION BY customer_id
                                      ORDER BY order_date DESC, row_id DESC) AS rn
            FROM silver.superstore_clean
        ) latest
        WHERE rn = 1;

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

        RAISE WARNING 'load_dim_customer failed: %', v_error;
    END;

    COMMIT;
END;
$$;