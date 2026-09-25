select unique_id, name, access, contract_enforced
from {{ info_schema('models') }} m
where {{ evaluator_check_in_scope('m') }}
  and access = 'public'
  and not coalesce(contract_enforced, false)
