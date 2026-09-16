with checks as ( 
    select 'row_count' as check_name,
           count(*)::text as actual,
           '51290' as expected
    from stg.sales_raw
    union all
    select 'column_count',
           count(*)::text,
           '26'
    from information_schema.columns
    where table_schema = 'stg' and table_name = 'sales_raw'
)
select check_name,
       actual,
       expected,
       case when actual = expected then 'PASS' else 'FAIL' end as result
from checks
order by case check_name
             when 'row_count' then 1
             when 'column_count' then 2
         end;
