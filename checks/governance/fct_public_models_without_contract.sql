-- public models without an enforced contract
select model.unique_id, model.name, model.access, model.contract_enforced
from {{ info_schema('models') }} model
where {{ evaluator_check_in_scope('model') }}
  and model.access = 'public'
  and not coalesce(model.contract_enforced, false)
