-- models with no parents at all (usually a hard-coded table reference instead of source() or ref())
select model.unique_id, model.name, model.original_file_path
from {{ info_schema('models') }} model
where {{ evaluator_check_in_scope('model') }}
  and not {{ evaluator_is_time_spine('model') }}
  and not exists (
      select 1
      from {{ info_schema('edges') }} edge
      where edge.child_unique_id = model.unique_id
  )
