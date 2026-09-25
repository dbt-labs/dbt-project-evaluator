-- public models without an enforced contract
select unique_id, name, access, contract_enforced
from {{ evaluator_models() }}
where access = 'public'
  and not coalesce(contract_enforced, false)
