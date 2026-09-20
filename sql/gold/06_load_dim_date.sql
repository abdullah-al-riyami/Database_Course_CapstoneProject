-- Procedure: build dim_date from the date range in silver and log the run
CREATE OR REPLACE PROCEDURE gold.load_dim_date()
LANGUAGE plpgsql
AS $$
DECLARE
    v_run_id       INTEGER;
    v_rows_loaded  INTEGER;
    v_first_date   DATE;
    v_last_date    DATE;
    v_error        TEXT;
BEGIN
    -- Part 1: log the start
    INSERT INTO control.etl_run_log (process_name, layer)
    VALUES ('load_dim_date', 'gold')
    RETURNING run_id INTO v_run_id;
    COMMIT;

    -- Part 2: do the load
    BEGIN
        -- Cover every day from the first order to the last shipment
        SELECT MIN(order_date), MAX(ship_date)
        INTO v_first_date, v_last_date
        FROM silver.superstore_clean;

        TRUNCATE TABLE gold.dim_date CASCADE;

        INSERT INTO gold.dim_date (
            date_key, full_date, year, quarter, month, month_name,
            day_of_month, day_name, is_weekend
        )
        SELECT
            TO_CHAR(d, 'YYYYMMDD')::INTEGER,      -- 2014-03-15 -> 20140315
            d,
            EXTRACT(YEAR    FROM d)::INTEGER,
            EXTRACT(QUARTER FROM d)::INTEGER,
            EXTRACT(MONTH   FROM d)::INTEGER,
            TO_CHAR(d, 'FMMonth'),                -- FM removes padding spaces
            EXTRACT(DAY     FROM d)::INTEGER,
            TO_CHAR(d, 'FMDay'),
            EXTRACT(ISODOW  FROM d) IN (6, 7)     -- ISO: 6 = Saturday, 7 = Sunday
        FROM generate_series(v_first_date, v_last_date, INTERVAL '1 day') AS g(day)
        CROSS JOIN LATERAL (SELECT g.day::DATE AS d) x;

        GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;

        -- Part 3a: log success
        UPDATE control.etl_run_log
        SET end_time    = clock_timestamp(),
            status      = 'SUCCESS',
            rows_loaded = v_rows_loaded
        WHERE run_id = v_run_id;

    EXCEPTION WHEN OTHERS THEN
        -- Part 3b: log failure
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;

        UPDATE control.etl_run_log
        SET end_time      = clock_timestamp(),
            status        = 'FAILED',
            error_message = v_error
        WHERE run_id = v_run_id;

        RAISE WARNING 'load_dim_date failed: %', v_error;
    END;

    COMMIT;
END;
$$;