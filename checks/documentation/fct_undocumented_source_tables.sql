-- source tables without a description
select unique_id, full_name as source_name, original_file_path
from {{ evaluator_sources() }}
where not {{ evaluator_is_documented('description') }}
