with missing as (
    select 'row_id' as column_name,
           count(*) filter (where row_id is null or row_id = '') as missing
    from stg.sales_raw
    union all
    select 'order_id',
           count(*) filter (where order_id is null or order_id = '')
    from stg.sales_raw
    union all
    select 'order_date',
           count(*) filter (where order_date is null or order_date = '')
    from stg.sales_raw
    union all
    select 'ship_date',
           count(*) filter (where ship_date is null or ship_date = '')
    from stg.sales_raw
    union all
    select 'ship_mode',
           count(*) filter (where ship_mode is null or ship_mode = '')
    from stg.sales_raw
    union all
    select 'customer_id',
           count(*) filter (where customer_id is null or customer_id = '')
    from stg.sales_raw
    union all
    select 'customer_name',
           count(*) filter (where customer_name is null or customer_name = '')
    from stg.sales_raw
    union all
    select 'segment',
           count(*) filter (where segment is null or segment = '')
    from stg.sales_raw
    union all
    select 'city',
           count(*) filter (where city is null or city = '')
    from stg.sales_raw
    union all
    select 'state',
           count(*) filter (where state is null or state = '')
    from stg.sales_raw
    union all
    select 'country',
           count(*) filter (where country is null or country = '')
    from stg.sales_raw
    union all
    select 'postal_code',
           count(*) filter (where postal_code is null or postal_code = '')
    from stg.sales_raw
    union all
    select 'market',
           count(*) filter (where market is null or market = '')
    from stg.sales_raw
    union all
    select 'region',
           count(*) filter (where region is null or region = '')
    from stg.sales_raw
    union all
    select 'product_id',
           count(*) filter (where product_id is null or product_id = '')
    from stg.sales_raw
    union all
    select 'category',
           count(*) filter (where category is null or category = '')
    from stg.sales_raw
    union all
    select 'sub_category',
           count(*) filter (where sub_category is null or sub_category = '')
    from stg.sales_raw
    union all
    select 'product_name',
           count(*) filter (where product_name is null or product_name = '')
    from stg.sales_raw
    union all
    select 'sales',
           count(*) filter (where sales is null or sales = '')
    from stg.sales_raw
    union all
    select 'quantity',
           count(*) filter (where quantity is null or quantity = '')
    from stg.sales_raw
    union all
    select 'discount',
           count(*) filter (where discount is null or discount = '')
    from stg.sales_raw
    union all
    select 'profit',
           count(*) filter (where profit is null or profit = '')
    from stg.sales_raw
    union all
    select 'shipping_cost',
           count(*) filter (where shipping_cost is null or shipping_cost = '')
    from stg.sales_raw
    union all
    select 'order_priority',
           count(*) filter (where order_priority is null or order_priority = '')
    from stg.sales_raw
),
total as (
    select count(*)::numeric as n
    from stg.sales_raw
)
select m.column_name,
       m.missing,
       round(m.missing * 100.0 / t.n, 2) as pct_missing
from missing m
cross join total t
order by m.missing desc, m.column_name;
