-- source tables with neither a warn_after nor an error_after freshness threshold
select source.unique_id,
       source.source_name || '.' || source.name as source_name
from {{ info_schema('sources') }} source
where {{ evaluator_check_in_scope('source') }}
  and (
      json_extract_string(source.config, '$.freshness.warn_after.count') is null
      and json_extract_string(source.config, '$.freshness.error_after.count') is null
  )
