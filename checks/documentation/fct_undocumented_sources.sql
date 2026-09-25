-- sources (the top-level `sources:` entry, not its tables) without a description.
-- One row per table of the undocumented source, so `--select` on any of its tables picks it up.
select source.unique_id,
       source.source_name,
       source.original_file_path
from {{ info_schema('sources') }} source
where {{ evaluator_check_in_scope('source') }}
  and not {{ evaluator_is_documented('source.source_description') }}
