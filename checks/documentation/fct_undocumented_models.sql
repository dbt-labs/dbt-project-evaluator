-- models without a description
select model.unique_id, model.name, model.original_file_path
from {{ info_schema('models') }} model
where {{ evaluator_check_in_scope('model') }}
  and not {{ evaluator_is_documented('model.description') }}
