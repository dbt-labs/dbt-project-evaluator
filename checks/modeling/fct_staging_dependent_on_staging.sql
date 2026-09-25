-- staging models that select from other staging models
select child_unique_id as unique_id, child_name as name, parent_name as parent
from {{ evaluator_edges() }}
where child_model_type = 'staging'
  and parent_model_type = 'staging'
