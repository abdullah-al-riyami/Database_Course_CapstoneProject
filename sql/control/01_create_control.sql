-- Control layer: records every ETL run
CREATE SCHEMA IF NOT EXISTS control;

DROP TABLE IF EXISTS control.etl_run_log;

CREATE TABLE control.etl_run_log (
    run_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    process_name   TEXT      NOT NULL,
    layer          TEXT,
    start_time     TIMESTAMP NOT NULL DEFAULT NOW(),
    end_time       TIMESTAMP,
    status         TEXT      NOT NULL DEFAULT 'RUNNING'
                   CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),
    rows_read      INTEGER,
    rows_loaded    INTEGER,
    error_message  TEXT
);