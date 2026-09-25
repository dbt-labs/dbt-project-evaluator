-- source tables without a description
select source.unique_id,
       source.source_name || '.' || source.name as source_name,
       source.original_file_path
from {{ info_schema('sources') }} source
where {{ evaluator_check_in_scope('source') }}
  and not {{ evaluator_is_documented('source.description') }}
