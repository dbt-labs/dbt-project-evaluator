-- models at the end of a chain of more than `chained_views_threshold` views/ephemeral models.
-- unique_id is the model at the end of the chain; `parent` is where the chain of views starts.
with recursive
edges as (select * from {{ evaluator_edges() }}),

-- walk downstream from every view, continuing only through views
chains(origin_name, unique_id, name, resource_type, is_view, distance) as (
    select parent_name, child_unique_id, child_name, child_resource_type,
           child_materialized in ('view', 'ephemeral'), 1
    from edges
    where parent_materialized in ('view', 'ephemeral')

    union

    select chains.origin_name, edges.child_unique_id, edges.child_name, edges.child_resource_type,
           edges.child_materialized in ('view', 'ephemeral'), chains.distance + 1
    from chains
    join edges on edges.parent_unique_id = chains.unique_id
    where chains.is_view
)

select unique_id, name as child, origin_name as parent, max(distance) as distance
from chains
where resource_type = 'model'
  and distance > {{ var('chained_views_threshold') }}
group by all
