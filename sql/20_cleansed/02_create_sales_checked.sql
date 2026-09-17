create view cleansed.sales_checked as
select
    row_id as source_row_id,
    case when row_id_ok then row_id::integer end as row_id,
    order_id,
    case when order_date_ok then to_date(order_date, 'DD-MM-YYYY') end as order_date,
    case when ship_date_ok then to_date(ship_date, 'DD-MM-YYYY') end as ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    city,
    state,
    country,
    lpad(postal_code, 5, '0') as postal_code,
    market,
    region,
    product_id,
    category,
    sub_category,
    btrim(regexp_replace(replace(product_name, chr(160), ' '), ' {2,}', ' ', 'g')) as product_name,
    case when sales_ok then sales::numeric end as sales,
    case when quantity_ok then quantity::integer end as quantity,
    case when discount_ok then discount::numeric end as discount,
    case when profit_ok then profit::numeric end as profit,
    case when shipping_cost_ok then shipping_cost::numeric end as shipping_cost,
    order_priority,
    load_ts,
    case
        when num_nulls(order_id, ship_mode, customer_id, customer_name, segment,
                       city, state, country, market, region, product_id,
                       category, sub_category, product_name, order_priority) > 0
            then 'a required field is missing'
        when not row_id_ok then 'row_id is missing or not a whole number'
        when not order_date_ok then 'order_date is missing or not a real DD-MM-YYYY date'
        when not ship_date_ok then 'ship_date is missing or not a real DD-MM-YYYY date'
        when not sales_ok then 'sales is missing or not a number'
        when not quantity_ok then 'quantity is missing or not a whole number'
        when not discount_ok then 'discount is missing or not a number'
        when not profit_ok then 'profit is missing or not a number'
        when not shipping_cost_ok then 'shipping_cost is missing or not a number'
        when to_date(ship_date, 'DD-MM-YYYY') < to_date(order_date, 'DD-MM-YYYY') then 'shipped before it was ordered'
        when sales::numeric <= 0 then 'sales is zero or negative'
        when quantity::integer <= 0 then 'quantity is zero or negative'
        when discount::numeric < 0 or discount::numeric > 1 then 'discount is outside 0 to 1'
        when shipping_cost::numeric < 0 then 'shipping_cost is negative'
    end as reject_reason
from (
    select *,
           coalesce(pg_input_is_valid(row_id, 'integer'), false) as row_id_ok,
           coalesce(order_date ~ '^\d{2}-\d{2}-\d{4}$'
                    and pg_input_is_valid(substr(order_date, 7, 4) || '-' || substr(order_date, 4, 2) || '-' || substr(order_date, 1, 2), 'date'), false) as order_date_ok,
           coalesce(ship_date ~ '^\d{2}-\d{2}-\d{4}$'
                    and pg_input_is_valid(substr(ship_date, 7, 4) || '-' || substr(ship_date, 4, 2) || '-' || substr(ship_date, 1, 2), 'date'), false) as ship_date_ok,
           coalesce(pg_input_is_valid(sales, 'numeric'), false) as sales_ok,
           coalesce(pg_input_is_valid(quantity, 'integer'), false) as quantity_ok,
           coalesce(pg_input_is_valid(discount, 'numeric'), false) as discount_ok,
           coalesce(pg_input_is_valid(profit, 'numeric'), false) as profit_ok,
           coalesce(pg_input_is_valid(shipping_cost, 'numeric'), false) as shipping_cost_ok
    from stg.sales_raw
) as flagged;
