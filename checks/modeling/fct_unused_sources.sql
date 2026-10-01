-- sources that nothing selects from (tests are not consumers)
select unique_id, full_name as source_name, original_file_path
from {{ evaluator_sources() }}
where unique_id not in (select parent_unique_id from {{ evaluator_edges() }})
