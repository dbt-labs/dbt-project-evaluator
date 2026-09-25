-- models without a description
select unique_id, name, original_file_path
from {{ evaluator_models() }}
where not is_documented
