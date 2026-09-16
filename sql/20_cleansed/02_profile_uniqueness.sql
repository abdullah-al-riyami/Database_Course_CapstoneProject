with cardinality as (
    select 'row_id' as column_name,
           count(distinct row_id) as distinct_values
    from stg.sales_raw
    union all
    select 'order_id',
           count(distinct order_id)
    from stg.sales_raw
    union all
    select 'order_date',
           count(distinct order_date)
    from stg.sales_raw
    union all
    select 'ship_date',
           count(distinct ship_date)
    from stg.sales_raw
    union all
    select 'ship_mode',
           count(distinct ship_mode)
    from stg.sales_raw
    union all
    select 'customer_id',
           count(distinct customer_id)
    from stg.sales_raw
    union all
    select 'customer_name',
           count(distinct customer_name)
    from stg.sales_raw
    union all
    select 'segment',
           count(distinct segment)
    from stg.sales_raw
    union all
    select 'city',
           count(distinct city)
    from stg.sales_raw
    union all
    select 'state',
           count(distinct state)
    from stg.sales_raw
    union all
    select 'country',
           count(distinct country)
    from stg.sales_raw
    union all
    select 'postal_code',
           count(distinct postal_code)
    from stg.sales_raw
    union all
    select 'market',
           count(distinct market)
    from stg.sales_raw
    union all
    select 'region',
           count(distinct region)
    from stg.sales_raw
    union all
    select 'product_id',
           count(distinct product_id)
    from stg.sales_raw
    union all
    select 'category',
           count(distinct category)
    from stg.sales_raw
    union all
    select 'sub_category',
           count(distinct sub_category)
    from stg.sales_raw
    union all
    select 'product_name',
           count(distinct product_name)
    from stg.sales_raw
    union all
    select 'sales',
           count(distinct sales)
    from stg.sales_raw
    union all
    select 'quantity',
           count(distinct quantity)
    from stg.sales_raw
    union all
    select 'discount',
           count(distinct discount)
    from stg.sales_raw
    union all
    select 'profit',
           count(distinct profit)
    from stg.sales_raw
    union all
    select 'shipping_cost',
           count(distinct shipping_cost)
    from stg.sales_raw
    union all
    select 'order_priority',
           count(distinct order_priority)
    from stg.sales_raw
)
select column_name,
       distinct_values
from cardinality
order by distinct_values desc, column_name;

select 'row_id' as test_name,
       count(*) as total_rows,
       count(distinct row_id) as distinct_combos,
       count(*) - count(distinct row_id) as duplicate_rows
from stg.sales_raw
union all
select 'order_id',
       count(*),
       count(distinct order_id),
       count(*) - count(distinct order_id)
from stg.sales_raw
union all
select '(order_id, product_id)',
       count(*),
       count(distinct (order_id, product_id)),
       count(*) - count(distinct (order_id, product_id))
from stg.sales_raw
union all
select '(order_id, product_id, row_id)',
       count(*),
       count(distinct (order_id, product_id, row_id)),
       count(*) - count(distinct (order_id, product_id, row_id))
from stg.sales_raw;

select order_id,
       product_id,
       count(*) as occurrences
from stg.sales_raw
group by order_id, product_id
having count(*) > 1
order by count(*) desc, order_id;
