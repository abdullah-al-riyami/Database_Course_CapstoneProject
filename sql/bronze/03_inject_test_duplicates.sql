-- FOR DEMONSTRATION ONLY
-- Duplicates 500 rows so the cleaning step can show it detects them.
-- Delete this file to load the original data without duplicates.

INSERT INTO stage.superstore_raw
SELECT *
FROM stage.superstore_raw
ORDER BY row_id::INT
LIMIT 500;