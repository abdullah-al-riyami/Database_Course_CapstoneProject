with typed as (
    select
        case when order_date ~ '^\d{2}-\d{2}-\d{4}$'
             then to_date(order_date, 'DD-MM-YYYY')
        end as order_dt,
        case when ship_date ~ '^\d{2}-\d{2}-\d{4}$'
             then to_date(ship_date, 'DD-MM-YYYY')
        end as ship_dt,
        case when pg_input_is_valid(sales, 'numeric')
             then sales::numeric
        end as sales_n,
        case when pg_input_is_valid(quantity, 'integer')
             then quantity::integer
        end as quantity_n,
        case when pg_input_is_valid(discount, 'numeric')
             then discount::numeric
        end as discount_n,
        case when pg_input_is_valid(profit, 'numeric')
             then profit::numeric
        end as profit_n,
        case when pg_input_is_valid(shipping_cost, 'numeric')
             then shipping_cost::numeric
        end as shipping_cost_n
    from stg.sales_raw
)
select 'order_dt' as measure,
       min(order_dt)::text as min_value,
       max(order_dt)::text as max_value,
       null::text as avg_value
from typed
union all
select 'ship_dt',
       min(ship_dt)::text,
       max(ship_dt)::text,
       null::text
from typed
union all
select 'sales_n',
       min(sales_n)::text,
       max(sales_n)::text,
       round(avg(sales_n), 4)::text
from typed
union all
select 'quantity_n',
       min(quantity_n)::text,
       max(quantity_n)::text,
       round(avg(quantity_n), 4)::text
from typed
union all
select 'discount_n',
       min(discount_n)::text,
       max(discount_n)::text,
       round(avg(discount_n), 4)::text
from typed
union all
select 'profit_n',
       min(profit_n)::text,
       max(profit_n)::text,
       round(avg(profit_n), 4)::text
from typed
union all
select 'shipping_cost_n',
       min(shipping_cost_n)::text,
       max(shipping_cost_n)::text,
       round(avg(shipping_cost_n), 4)::text
from typed;

with typed as (
    select
        case when order_date ~ '^\d{2}-\d{2}-\d{4}$'
             then to_date(order_date, 'DD-MM-YYYY')
        end as order_dt,
        case when ship_date ~ '^\d{2}-\d{2}-\d{4}$'
             then to_date(ship_date, 'DD-MM-YYYY')
        end as ship_dt,
        case when pg_input_is_valid(sales, 'numeric')
             then sales::numeric
        end as sales_n,
        case when pg_input_is_valid(quantity, 'integer')
             then quantity::integer
        end as quantity_n,
        case when pg_input_is_valid(discount, 'numeric')
             then discount::numeric
        end as discount_n,
        case when pg_input_is_valid(profit, 'numeric')
             then profit::numeric
        end as profit_n,
        case when pg_input_is_valid(shipping_cost, 'numeric')
             then shipping_cost::numeric
        end as shipping_cost_n
    from stg.sales_raw
)
select 'sales_n <= 0' as finding,
       count(*) as row_count
from typed
where sales_n <= 0
union all
select 'profit_n < 0',
       count(*)
from typed
where profit_n < 0
union all
select 'quantity_n <= 0',
       count(*)
from typed
where quantity_n <= 0
union all
select 'discount_n < 0',
       count(*)
from typed
where discount_n < 0
union all
select 'discount_n > 1',
       count(*)
from typed
where discount_n > 1
union all
select 'ship_dt < order_dt',
       count(*)
from typed
where ship_dt < order_dt
union all
select 'order_dt outside 2011-01-01 .. 2014-12-31',
       count(*)
from typed
where order_dt < date '2011-01-01'
   or order_dt > date '2014-12-31'
union all
select 'shipping_cost_n < 0',
       count(*)
from typed
where shipping_cost_n < 0
order by row_count desc;
