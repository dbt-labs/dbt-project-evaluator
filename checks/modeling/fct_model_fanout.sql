-- models with at least `models_fanout_threshold` direct leaf children
-- (a leaf is a model with no children of its own, ignoring tests)
with edges as (select * from {{ evaluator_edges() }})

select parent_unique_id as unique_id, parent_name as name, count(*) as leaf_children
from edges
where parent_resource_type = 'model'
  and child_resource_type = 'model'
  and child_unique_id not in (select parent_unique_id from edges)
group by all
having leaf_children >= {{ var('models_fanout_threshold') }}
