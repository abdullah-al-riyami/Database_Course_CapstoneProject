-- Procedure: load fact_sales from silver, looking up every dimension key
CREATE OR REPLACE PROCEDURE gold.load_fact_sales()
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
    VALUES ('load_fact_sales', 'gold')
    RETURNING run_id INTO v_run_id;
    COMMIT;

    -- Part 2: do the load
    BEGIN
        SELECT COUNT(*) INTO v_rows_read FROM silver.superstore_clean;

        TRUNCATE TABLE gold.fact_sales RESTART IDENTITY;

        INSERT INTO gold.fact_sales (
            row_id, order_id,
            order_date_key, ship_date_key,
            customer_key, product_key, location_key,
            ship_mode, order_priority,
            sales, quantity, discount, profit, shipping_cost
        )
        SELECT
            s.row_id,
            s.order_id,
            TO_CHAR(s.order_date, 'YYYYMMDD')::INTEGER,
            TO_CHAR(s.ship_date,  'YYYYMMDD')::INTEGER,
            c.customer_key,
            p.product_key,
            l.location_key,
            s.ship_mode,
            s.order_priority,
            s.sales,
            s.quantity,
            s.discount,
            s.profit,
            s.shipping_cost
        FROM silver.superstore_clean s
        JOIN gold.dim_customer c
          ON c.customer_id = s.customer_id
        JOIN gold.dim_product p
          ON  p.product_id   = s.product_id
          AND p.product_name = s.product_name
        JOIN gold.dim_location l
          ON  l.city    = s.city
          AND l.state   = s.state
          AND l.country = s.country
          AND l.region  = s.region
          AND l.market  = s.market
          AND l.postal_code IS NOT DISTINCT FROM s.postal_code;

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

        RAISE WARNING 'load_fact_sales failed: %', v_error;
    END;

    COMMIT;
END;
$$;