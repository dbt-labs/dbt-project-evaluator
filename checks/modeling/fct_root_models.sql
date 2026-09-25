-- models with no parents at all (usually a hard-coded table reference instead of source() or ref())
select unique_id, name, original_file_path
from {{ evaluator_models() }}
where not is_time_spine
  and unique_id not in (select child_unique_id from {{ info_schema('edges') }})
