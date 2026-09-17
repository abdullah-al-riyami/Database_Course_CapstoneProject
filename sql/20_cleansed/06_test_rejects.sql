begin;

insert into stg.sales_raw (row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name, segment, city, state, country, postal_code, market, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit, shipping_cost, order_priority)
values
    ('900001', 'TEST-1', '31-02-2013', '01-03-2013', 'Same Day', 'T-1', 'Test Customer', 'Consumer', 'Test City', 'Test State', 'Test Country', null, 'US', 'East', 'P-1', 'Furniture', 'Chairs', 'Test Chair', '10.5', '1', '0', '1', '1', 'Low'),
    ('900002', 'TEST-2', '01-03-2013', '01-03-2013', 'Same Day', 'T-1', 'Test Customer', 'Consumer', 'Test City', 'Test State', 'Test Country', null, 'US', 'East', 'P-1', 'Furniture', 'Chairs', 'Test Chair', '10.5', '0', '0', '1', '1', 'Low'),
    ('900003', 'TEST-3', '01-03-2013', '01-03-2013', 'Same Day', 'T-1', 'Test Customer', 'Consumer', 'Test City', 'Test State', 'Test Country', null, 'US', 'East', 'P-1', 'Furniture', 'Chairs', 'Test Chair', 'abc', '1', '0', '1', '1', 'Low'),
    ('900004', 'TEST-4', '01-03-2013', '01-03-2013', 'Same Day', null, 'Test Customer', 'Consumer', 'Test City', 'Test State', 'Test Country', null, 'US', 'East', 'P-1', 'Furniture', 'Chairs', 'Test Chair', '10.5', '1', '0', '1', '1', 'Low'),
    ('900005', 'TEST-5', '05-03-2013', '01-03-2013', 'Same Day', 'T-1', 'Test Customer', 'Consumer', 'Test City', 'Test State', 'Test Country', null, 'US', 'East', 'P-1', 'Furniture', 'Chairs', 'Test Chair', '10.5', '1', '0', '1', '1', 'Low');

select source_row_id,
       reject_reason
from cleansed.dq_rejects
order by source_row_id;

select (select count(*) from stg.sales_raw) as staging_rows_during_test,
       (select count(*) from cleansed.sales) as clean_rows_during_test,
       (select count(*) from cleansed.dq_rejects) as rejected_rows_during_test;

rollback;
