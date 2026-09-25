-- models sitting at the end of a chain of more than `chained_views_threshold` views/ephemeral models.
-- unique_id is the model at the end of the chain; `parent` is where the chain of views starts.
with recursive nodes as (
    select node.unique_id, node.name, node.resource_type, node.materialized
    from {{ evaluator_nodes() }} node
    where {{ evaluator_check_in_scope('node') }}
),

direct_edges as (
    select distinct edge.parent_unique_id, edge.child_unique_id
    from {{ info_schema('edges') }} edge
    join nodes parent on parent.unique_id = edge.parent_unique_id
    join nodes child on child.unique_id = edge.child_unique_id
),

-- walk downstream only through views and ephemeral models
chains(origin, current_node, distance, path) as (
    select edge.parent_unique_id,
           edge.child_unique_id,
           1,
           [edge.parent_unique_id, edge.child_unique_id]
    from direct_edges edge
    join nodes parent on parent.unique_id = edge.parent_unique_id
    where coalesce(parent.materialized, '') in ('view', 'ephemeral')

    union all

    select chains.origin,
           edge.child_unique_id,
           chains.distance + 1,
           list_append(chains.path, edge.child_unique_id)
    from chains
    join nodes current_node on current_node.unique_id = chains.current_node
    join direct_edges edge on edge.parent_unique_id = chains.current_node
    where coalesce(current_node.materialized, '') in ('view', 'ephemeral')
      and not list_contains(chains.path, edge.child_unique_id)
)

select child.unique_id,
       child.name as child,
       parent.name as parent,
       max(chains.distance) as distance
from chains
join nodes parent on parent.unique_id = chains.origin
join nodes child on child.unique_id = chains.current_node
where child.resource_type = 'model'
  and chains.distance > {{ var('chained_views_threshold') }}
group by child.unique_id, child.name, parent.name
