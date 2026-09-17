\x on

select
    (select count(*) from stg.sales_raw) as staging_rows,
    (select count(*) from cleansed.sales) as clean_rows,
    (select count(*) from cleansed.dq_rejects) as rejected_rows,
    (select count(*) from cleansed.sales)
        + (select count(*) from cleansed.dq_rejects)
        = (select count(*) from stg.sales_raw) as every_row_accounted_for,
    (select sum(c.sales) = sum(s.sales::numeric)
       from cleansed.sales c
       join stg.sales_raw s on s.row_id = c.row_id::text) as sales_values_unchanged,
    (select sum(c.profit) = sum(s.profit::numeric)
       from cleansed.sales c
       join stg.sales_raw s on s.row_id = c.row_id::text) as profit_values_unchanged,
    (select count(*) from cleansed.sales where length(postal_code) <> 5) as postal_codes_not_5_characters,
    (select count(*) from cleansed.sales where product_name like '%' || chr(160) || '%') as product_names_with_odd_spaces,
    (select count(*) from cleansed.sales where product_name <> btrim(product_name)) as product_names_untrimmed,
    (select count(distinct (country, market, region)) from cleansed.sales) as expected_country_dim_rows,
    (select count(distinct (customer_id, customer_name, segment)) from cleansed.sales) as expected_customer_dim_rows,
    (select count(distinct (product_id, product_name)) from cleansed.sales) as expected_product_dim_rows;

\x off

select reject_reason,
       count(*) as rows_rejected
from cleansed.dq_rejects
group by reject_reason
order by rows_rejected desc;
