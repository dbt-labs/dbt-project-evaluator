with recursive scoped_nodes as (
    select *
    from {{ info_schema('graph_nodes') }} node
    where {{ evaluator_check_in_scope('node') }}
),
direct_edges as (
    select edge.parent_unique_id, edge.child_unique_id
    from {{ info_schema('edges') }} edge
    join scoped_nodes parent on parent.unique_id = edge.parent_unique_id
    join scoped_nodes child on child.unique_id = edge.child_unique_id
),
chains(origin, current_node, distance, path, chain_of_views) as (
    select edge.parent_unique_id,
           edge.child_unique_id,
           1,
           [edge.parent_unique_id, edge.child_unique_id],
           coalesce(parent.materialized, '') in ('view', 'ephemeral')
    from direct_edges edge
    join scoped_nodes parent on parent.unique_id = edge.parent_unique_id

    union all

    select chains.origin,
           edge.child_unique_id,
           chains.distance + 1,
           list_append(chains.path, edge.child_unique_id),
           chains.chain_of_views
             and coalesce(current_node.materialized, '') in ('view', 'ephemeral')
    from chains
    join scoped_nodes current_node
      on current_node.unique_id = chains.current_node
    join direct_edges edge
      on edge.parent_unique_id = chains.current_node
    where not list_contains(chains.path, edge.child_unique_id)
),
violations as (
    select parent.name as parent,
           child.name as child,
           chains.distance,
           chains.path
    from chains
    join scoped_nodes parent on parent.unique_id = chains.origin
    join scoped_nodes child on child.unique_id = chains.current_node
    where chains.chain_of_views
      and child.resource_type = 'model'
      and chains.distance > {{ var('chained_views_threshold', 5) }}
)
select * from violations
