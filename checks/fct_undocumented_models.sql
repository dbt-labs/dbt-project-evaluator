select unique_id, name, original_file_path
from {{ info_schema('models') }} m
where {{ evaluator_check_in_scope('m') }}
  and nullif(trim(description), '') is null
