select unique_id, name, source_name, original_file_path
from {{ info_schema('sources') }} s
where {{ evaluator_check_in_scope('s') }}
  and nullif(trim(description), '') is null
