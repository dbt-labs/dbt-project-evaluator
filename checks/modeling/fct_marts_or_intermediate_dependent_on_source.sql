-- marts and intermediate models that select directly from a source
with models as (
    select model.unique_id,
           model.name,
           {{ evaluator_model_type('model') }} as model_type
    from {{ info_schema('models') }} model
    where {{ evaluator_check_in_scope('model') }}
)

select child.unique_id,
       child.name,
       child.model_type,
       source.source_name || '.' || source.name as source_name
from models child
join {{ info_schema('edges') }} edge on edge.child_unique_id = child.unique_id
join {{ info_schema('sources') }} source on source.unique_id = edge.parent_unique_id
where {{ evaluator_check_in_scope('source') }}
  and child.model_type in ('marts', 'intermediate')
