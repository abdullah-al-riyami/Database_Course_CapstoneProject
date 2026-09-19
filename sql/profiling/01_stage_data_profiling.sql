-- =====================================================================
-- Data profiling: stage.superstore_raw
-- Purpose: find data-quality issues before building the silver layer.
-- Run these queries manually (this folder is not run by init.sql).
-- Results are summarised in docs/data_profiling.md
-- =====================================================================


-- =====================================================================
-- Check 0: Row and column counts
-- =====================================================================
-- Why:     Confirm the load is complete before profiling anything.
-- Result:  51,790 rows (51,290 from the CSV + 500 planted duplicates), 24 columns.

SELECT COUNT(*) AS total_rows
FROM stage.superstore_raw;

SELECT COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'stage'
  AND table_name   = 'superstore_raw';


-- =====================================================================
-- Check 1: Duplicate row IDs
-- =====================================================================
-- Why:     row_id should identify each sales line uniquely.
-- Result:  500 duplicated row IDs, each appearing twice. These were
--          planted on purpose by bronze/03_inject_test_duplicates.sql.
--          The original file has no duplicates.
-- Action:  Silver layer keeps one copy of each row_id.

SELECT row_id, COUNT(*) AS occurrences
FROM stage.superstore_raw
GROUP BY row_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS duplicated_row_ids
FROM (
    SELECT row_id
    FROM stage.superstore_raw
    GROUP BY row_id
    HAVING COUNT(*) > 1
) d;


-- =====================================================================
-- Check 2: Missing values in important columns
-- =====================================================================
-- Why:     IDs are required to link sales to customers and products.
-- Result:  No missing order, customer or product IDs.
--          postal_code is blank in 41,296 of the original 51,290 rows (~80%).
--          Only United States rows have postal codes (9,994 of 9,994).
-- Action:  Blanks outside the US are expected, not errors.
--          Silver layer stores them as NULL.

SELECT
    COUNT(*) FILTER (WHERE TRIM(order_id)    = '' OR order_id    IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE TRIM(customer_id) = '' OR customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE TRIM(product_id)  = '' OR product_id  IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE TRIM(postal_code) = '' OR postal_code IS NULL) AS missing_postal_code
FROM stage.superstore_raw;

-- Which countries have postal codes?
SELECT country,
       COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE TRIM(postal_code) <> '') AS rows_with_postal
FROM stage.superstore_raw
GROUP BY country
HAVING COUNT(*) FILTER (WHERE TRIM(postal_code) <> '') > 0;


-- =====================================================================
-- Check 3: Date format
-- =====================================================================
-- Why:     Dates are stored as text and must be converted correctly.
-- Result:  Format is DD-MM-YYYY (e.g. 31-07-2012; there is no month 31).
-- Action:  Silver layer converts with TO_DATE(order_date, 'DD-MM-YYYY').
--          Reading them as MM-DD would silently swap day and month.

SELECT order_date, ship_date
FROM stage.superstore_raw
LIMIT 10;


-- =====================================================================
-- Check 4: US postal codes missing their leading zero
-- =====================================================================
-- Why:     US postal codes (ZIP codes) must be exactly 5 digits.
-- Result:  449 codes have 4 digits, 9,545 have 5.
--          The 4-digit codes are all in northeastern states, whose
--          ZIP codes start with 0 (e.g. Lakewood, NJ: 8701 -> 08701).
-- Action:  Silver layer pads them with LPAD(postal_code, 5, '0').

SELECT LENGTH(postal_code) AS code_length, COUNT(*) AS row_count
FROM stage.superstore_raw
WHERE TRIM(postal_code) <> ''
GROUP BY LENGTH(postal_code)
ORDER BY code_length;

-- Which states do the 4-digit codes belong to?
SELECT state, city, postal_code
FROM stage.superstore_raw
WHERE LENGTH(postal_code) = 4
GROUP BY state, city, postal_code
ORDER BY state
LIMIT 15;


-- =====================================================================
-- Check 5: Same product ID used for different products
-- =====================================================================
-- Why:     A product ID should identify exactly one product.
-- Result:  457 product IDs are used for 2 to 4 different product names.
--          Example: OFF-PA-10004673 is used for four different brands
--          (Eaton, Enermax, Green Bar, Xerox), all in Office Supplies > Paper.
-- Action:  A product is identified by product_id + product_name together.

SELECT COUNT(*) AS shared_product_ids
FROM (
    SELECT product_id
    FROM stage.superstore_raw
    GROUP BY product_id
    HAVING COUNT(DISTINCT product_name) > 1
) x;

-- Worst cases first
SELECT product_id, COUNT(DISTINCT product_name) AS different_names
FROM stage.superstore_raw
GROUP BY product_id
HAVING COUNT(DISTINCT product_name) > 1
ORDER BY different_names DESC
LIMIT 20;

-- Example
SELECT DISTINCT product_id, product_name, category, sub_category
FROM stage.superstore_raw
WHERE product_id = 'OFF-PA-10004673';


-- =====================================================================
-- Check 6: Same order ID used for different customers
-- =====================================================================
-- Why:     An order should belong to exactly one customer.
-- Result:  659 order IDs are shared by different customers.
--          Example: AG-2012-2220 is used by Mike Vittorini (09-11-2012)
--          and Patrick O'Donnell (26-12-2012), both in Algeria:
--          two separate orders six weeks apart with the same number.
-- Action:  An order is identified by order_id + customer_id.
--          A sales line is identified by row_id.
--          COUNT(DISTINCT order_id) would undercount orders.

SELECT COUNT(*) AS shared_order_ids
FROM (
    SELECT order_id
    FROM stage.superstore_raw
    GROUP BY order_id
    HAVING COUNT(DISTINCT customer_id) > 1
) x;

-- Example
SELECT order_id, customer_id, customer_name, country, market, order_date
FROM stage.superstore_raw
WHERE order_id = 'AG-2012-2220'
ORDER BY customer_id;
