-- models that read from both a source and another model
with parents as (
    select child.unique_id,
           child.name,
           count(distinct source.unique_id) as source_parents,
           count(distinct model.unique_id) as model_parents
    from {{ info_schema('models') }} child
    join {{ info_schema('edges') }} edge on edge.child_unique_id = child.unique_id
    left join {{ info_schema('sources') }} source on source.unique_id = edge.parent_unique_id
    left join {{ info_schema('models') }} model on model.unique_id = edge.parent_unique_id
    where {{ evaluator_check_in_scope('child') }}
    group by child.unique_id, child.name
)

select unique_id, name, source_parents, model_parents
from parents
where source_parents > 0
  and model_parents > 0
