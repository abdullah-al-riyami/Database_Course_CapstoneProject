with validity as (
    select 'order_date_format' as column_name,
           'date' as target_type,
           count(*) filter (
               where order_date is not null
                 and order_date <> ''
                 and order_date !~ '^\d{2}-\d{2}-\d{4}$'
           ) as invalid_count
    from stg.sales_raw
    union all
    select 'order_date_real',
           'date',
           count(*) filter (
               where order_date ~ '^\d{2}-\d{2}-\d{4}$'
                 and not pg_input_is_valid(
                     substr(order_date, 7, 4) || '-' || substr(order_date, 4, 2) || '-' || substr(order_date, 1, 2),
                     'date'
                 )
           )
    from stg.sales_raw
    union all
    select 'ship_date_format',
           'date',
           count(*) filter (
               where ship_date is not null
                 and ship_date <> ''
                 and ship_date !~ '^\d{2}-\d{2}-\d{4}$'
           )
    from stg.sales_raw
    union all
    select 'ship_date_real',
           'date',
           count(*) filter (
               where ship_date ~ '^\d{2}-\d{2}-\d{4}$'
                 and not pg_input_is_valid(
                     substr(ship_date, 7, 4) || '-' || substr(ship_date, 4, 2) || '-' || substr(ship_date, 1, 2),
                     'date'
                 )
           )
    from stg.sales_raw
    union all
    select 'row_id',
           'integer',
           count(*) filter (
               where row_id is not null
                 and row_id <> ''
                 and not pg_input_is_valid(row_id, 'integer')
           )
    from stg.sales_raw
    union all
    select 'quantity',
           'integer',
           count(*) filter (
               where quantity is not null
                 and quantity <> ''
                 and not pg_input_is_valid(quantity, 'integer')
           )
    from stg.sales_raw
    union all
    select 'sales',
           'numeric',
           count(*) filter (
               where sales is not null
                 and sales <> ''
                 and not pg_input_is_valid(sales, 'numeric')
           )
    from stg.sales_raw
    union all
    select 'discount',
           'numeric',
           count(*) filter (
               where discount is not null
                 and discount <> ''
                 and not pg_input_is_valid(discount, 'numeric')
           )
    from stg.sales_raw
    union all
    select 'profit',
           'numeric',
           count(*) filter (
               where profit is not null
                 and profit <> ''
                 and not pg_input_is_valid(profit, 'numeric')
           )
    from stg.sales_raw
    union all
    select 'shipping_cost',
           'numeric',
           count(*) filter (
               where shipping_cost is not null
                 and shipping_cost <> ''
                 and not pg_input_is_valid(shipping_cost, 'numeric')
           )
    from stg.sales_raw
    union all
    select 'postal_code',
           'integer',
           count(*) filter (
               where postal_code is not null
                 and postal_code <> ''
                 and not pg_input_is_valid(postal_code, 'integer')
           )
    from stg.sales_raw
)
select column_name,
       target_type,
       invalid_count
from validity
order by invalid_count desc, column_name;

