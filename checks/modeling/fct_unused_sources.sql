-- sources that nothing selects from
select source.unique_id,
       source.source_name || '.' || source.name as source_name,
       source.original_file_path
from {{ info_schema('sources') }} source
where {{ evaluator_check_in_scope('source') }}
  and not exists (
      select 1
      from {{ info_schema('edges') }} edge
      where edge.parent_unique_id = source.unique_id
  )
