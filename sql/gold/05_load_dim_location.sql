-- Procedure: load dim_location from silver and log the run
CREATE OR REPLACE PROCEDURE gold.load_dim_location()
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
    VALUES ('load_dim_location', 'gold')
    RETURNING run_id INTO v_run_id;
    COMMIT;

    -- Part 2: do the load
    BEGIN
        SELECT COUNT(*) INTO v_rows_read FROM silver.superstore_clean;

        TRUNCATE TABLE gold.dim_location RESTART IDENTITY CASCADE;

        -- One row per distinct delivery place
        INSERT INTO gold.dim_location (city, state, country, postal_code, region, market)
        SELECT DISTINCT city, state, country, postal_code, region, market
        FROM silver.superstore_clean;

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

        RAISE WARNING 'load_dim_location failed: %', v_error;
    END;

    COMMIT;
END;
$$;