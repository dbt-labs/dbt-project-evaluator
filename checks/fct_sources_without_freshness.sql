select distinct unique_id, source_name, name
from {{ info_schema('sources') }} s
where {{ evaluator_check_in_scope('s') }}
  and (
      freshness is null
      or (
          json_extract_string(freshness, '$.warn_after.count') is null
          and json_extract_string(freshness, '$.error_after.count') is null
      )
  )
