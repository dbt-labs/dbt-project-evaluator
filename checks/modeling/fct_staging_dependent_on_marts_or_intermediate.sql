-- staging models that select from marts or intermediate models
select child_unique_id as unique_id, child_name as name, parent_name as parent, parent_model_type
from {{ evaluator_edges() }}
where child_model_type = 'staging'
  and parent_model_type in ('marts', 'intermediate')
