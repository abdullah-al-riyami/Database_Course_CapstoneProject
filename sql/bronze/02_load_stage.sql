-- Procedure: load the CSV into the stage table and log the run
CREATE OR REPLACE PROCEDURE stage.load_stage()
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id       INTEGER;
    v_rows_loaded  INTEGER;
    v_error        TEXT;
BEGIN
    -- Part 1: log the start
    INSERT INTO control.etl_run_log (process_name, layer)  -- only these two are given; the rest use defaults or stay empty
    VALUES ('load_stage', 'bronze')                        -- process_name = 'load_stage', layer = 'bronze'
    RETURNING run_id INTO v_run_id;                        -- run_id is generated automatically; save it to update this row later
    COMMIT;                                                -- save the RUNNING row now, so the run is recorded even if the load fails

    -- Part 2: do the load
    BEGIN
        TRUNCATE TABLE stage.superstore_raw;

        COPY stage.superstore_raw (
            row_id, order_id, order_date, ship_date, ship_mode,
            customer_id, customer_name, segment,
            city, state, country, postal_code, market, region,
            product_id, category, sub_category, product_name,
            sales, quantity, discount, profit, shipping_cost, order_priority
        )
        FROM '/data/Global_Superstore2.csv'
        WITH (FORMAT csv, HEADER true, ENCODING 'LATIN1');

        SELECT COUNT(*) INTO v_rows_loaded FROM stage.superstore_raw;

        -- Part 3a: log success
        UPDATE control.etl_run_log
        SET end_time    = clock_timestamp(),   -- actual current time (NOW() would return the transaction start)
            status      = 'SUCCESS',
            rows_loaded = v_rows_loaded
        WHERE run_id = v_run_id;

    EXCEPTION WHEN OTHERS THEN  -- catches any type of error, but only from the statements in this block (Part 2)
        -- Part 3b: log failure
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;

        UPDATE control.etl_run_log
        SET end_time      = clock_timestamp(),
            status        = 'FAILED',
            error_message = v_error
        WHERE run_id = v_run_id;

        RAISE WARNING 'load_stage failed: %', v_error;
    END;

    COMMIT;
END;
$$;