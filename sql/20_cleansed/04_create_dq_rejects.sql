create view cleansed.dq_rejects as
select source_row_id,
       reject_reason,
       load_ts
from cleansed.sales_checked
where reject_reason is not null;
