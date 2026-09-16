with consistency as (
    select 'product_id -> product_name' as relationship,
           count(*) as parents_with_conflicts
    from (
        select product_id
        from stg.sales_raw
        group by product_id
        having count(distinct product_name) > 1
    ) s
    union all
    select 'product_id -> category',
           count(*)
    from (
        select product_id
        from stg.sales_raw
        group by product_id
        having count(distinct category) > 1
    ) s
    union all
    select 'product_id -> sub_category',
           count(*)
    from (
        select product_id
        from stg.sales_raw
        group by product_id
        having count(distinct sub_category) > 1
    ) s
    union all
    select 'customer_id -> customer_name',
           count(*)
    from (
        select customer_id
        from stg.sales_raw
        group by customer_id
        having count(distinct customer_name) > 1
    ) s
    union all
    select 'customer_id -> segment',
           count(*)
    from (
        select customer_id
        from stg.sales_raw
        group by customer_id
        having count(distinct segment) > 1
    ) s
    union all
    select 'country -> market',
           count(*)
    from (
        select country
        from stg.sales_raw
        group by country
        having count(distinct market) > 1
    ) s
    union all
    select 'country -> region',
           count(*)
    from (
        select country
        from stg.sales_raw
        group by country
        having count(distinct region) > 1
    ) s
    union all
    select 'country -> (market, region)',
           count(*)
    from (
        select country
        from stg.sales_raw
        group by country
        having count(distinct (market, region)) > 1
    ) s
    union all
    select 'state -> country',
           count(*)
    from (
        select state
        from stg.sales_raw
        group by state
        having count(distinct country) > 1
    ) s
    union all
    select 'city -> country',
           count(*)
    from (
        select city
        from stg.sales_raw
        group by city
        having count(distinct country) > 1
    ) s
    union all
    select 'order_id -> customer_id',
           count(*)
    from (
        select order_id
        from stg.sales_raw
        group by order_id
        having count(distinct customer_id) > 1
    ) s
    union all
    select 'order_id -> order_date',
           count(*)
    from (
        select order_id
        from stg.sales_raw
        group by order_id
        having count(distinct order_date) > 1
    ) s
    union all
    select 'order_id -> ship_date',
           count(*)
    from (
        select order_id
        from stg.sales_raw
        group by order_id
        having count(distinct ship_date) > 1
    ) s
)
select relationship,
       parents_with_conflicts
from consistency
order by parents_with_conflicts desc, relationship;

select product_id,
       string_agg(distinct product_name, ' | ') as conflicting_names
from stg.sales_raw
group by product_id
having count(distinct product_name) > 1
order by count(distinct product_name) desc, product_id
limit 10;

select country,
       string_agg(distinct market || ' / ' || region, ' | ') as conflicting_pairs
from stg.sales_raw
group by country
having count(distinct (market, region)) > 1
order by country;
