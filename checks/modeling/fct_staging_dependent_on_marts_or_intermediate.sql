-- staging models that select from marts or intermediate models
with models as (
    select model.unique_id,
           model.name,
           {{ evaluator_model_type('model') }} as model_type
    from {{ info_schema('models') }} model
    where {{ evaluator_check_in_scope('model') }}
)

select child.unique_id,
       child.name,
       parent.name as parent,
       parent.model_type as parent_model_type
from models child
join {{ info_schema('edges') }} edge on edge.child_unique_id = child.unique_id
join models parent on parent.unique_id = edge.parent_unique_id
where child.model_type = 'staging'
  and parent.model_type in ('marts', 'intermediate')
