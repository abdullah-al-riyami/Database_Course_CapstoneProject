truncate table stg.sales_raw;

\copy stg.sales_raw (row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name, segment, city, state, country, postal_code, market, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit, shipping_cost, order_priority) from '/data/Global_Superstore2.csv' with (format csv, header true, encoding 'WIN1252')
