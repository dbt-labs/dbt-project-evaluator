-- sources (the top-level `sources:` entry) without a description; one row per source, `unique_id` being one of its tables
select min(unique_id) as unique_id,
       source_name,
       any_value(original_file_path) as original_file_path
from {{ evaluator_sources() }}
where not {{ evaluator_is_documented('source_description') }}
group by package_name, source_name
