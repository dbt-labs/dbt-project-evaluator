-- sources (the top-level `sources:` entry) without a description; one row per table of the source
select unique_id, source_name, original_file_path
from {{ evaluator_sources() }}
where not {{ evaluator_is_documented('source_description') }}
