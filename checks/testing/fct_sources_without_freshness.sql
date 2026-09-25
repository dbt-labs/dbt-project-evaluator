-- source tables with neither a warn_after nor an error_after freshness threshold
select unique_id, full_name as source_name
from {{ evaluator_sources() }}
where json_extract_string(config, '$.freshness.warn_after.count') is null
  and json_extract_string(config, '$.freshness.error_after.count') is null
