-- models with at least `models_fanout_threshold` direct leaf children
-- (a leaf is a model with no children of its own, ignoring tests)
with models as (
    select model.unique_id, model.name
    from {{ info_schema('models') }} model
    where {{ evaluator_check_in_scope('model') }}
),

leaf_models as (
    select models.unique_id
    from models
    where not exists (
        select 1
        from {{ info_schema('edges') }} edge
        join {{ evaluator_nodes() }} child on child.unique_id = edge.child_unique_id
        where edge.parent_unique_id = models.unique_id
          and child.resource_type not in ('test', 'data_test', 'unit_test')
          and {{ evaluator_check_in_scope('child') }}
    )
),

fanout as (
    select parent.unique_id,
           parent.name,
           count(distinct edge.child_unique_id) as leaf_children
    from models parent
    join {{ info_schema('edges') }} edge on edge.parent_unique_id = parent.unique_id
    join leaf_models leaf on leaf.unique_id = edge.child_unique_id
    group by parent.unique_id, parent.name
)

select unique_id, name, leaf_children
from fanout
where leaf_children >= {{ var('models_fanout_threshold') }}
