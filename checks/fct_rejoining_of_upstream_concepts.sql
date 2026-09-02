with recursive scoped_nodes as (
    select *
    from {{ info_schema('graph_nodes') }} node
    where {{ evaluator_check_in_scope('node') }}
      and resource_type not in ('exposure', 'metric')
),
direct_edges as (
    select edge.parent_unique_id, edge.child_unique_id
    from {{ info_schema('edges') }} edge
    join scoped_nodes parent on parent.unique_id = edge.parent_unique_id
    join scoped_nodes child on child.unique_id = edge.child_unique_id
),
paths(parent_unique_id, child_unique_id, distance, path) as (
    select parent_unique_id, child_unique_id, 1,
           [parent_unique_id, child_unique_id]
    from direct_edges

    union all

    select paths.parent_unique_id,
           edge.child_unique_id,
           paths.distance + 1,
           list_append(paths.path, edge.child_unique_id)
    from paths
    join direct_edges edge
      on edge.parent_unique_id = paths.child_unique_id
    where not list_contains(paths.path, edge.child_unique_id)
),
rejoined as (
    select parent_unique_id, child_unique_id
    from paths
    group by parent_unique_id, child_unique_id
    having count(*) filter (where distance = 1) > 0
       and count(*) filter (where distance = 2) > 0
),
single_use as (
    select parent_unique_id
    from direct_edges
    group by parent_unique_id
    having count(*) = 1
),
triads as (
    select distinct rejoined.parent_unique_id,
           rejoined.child_unique_id,
           first_hop.child_unique_id as parent_and_child_unique_id
    from rejoined
    join direct_edges first_hop
      on first_hop.parent_unique_id = rejoined.parent_unique_id
    join direct_edges second_hop
      on second_hop.parent_unique_id = first_hop.child_unique_id
     and second_hop.child_unique_id = rejoined.child_unique_id
    join single_use
      on single_use.parent_unique_id = first_hop.child_unique_id
)
select parent.name as parent,
       case
           when child.version is null then child.name
           else child.name || '.v' || cast(child.version as varchar)
       end as child,
       parent_and_child.name as parent_and_child,
       true as is_loop_independent
from triads
join scoped_nodes parent on parent.unique_id = triads.parent_unique_id
join scoped_nodes child on child.unique_id = triads.child_unique_id
join scoped_nodes parent_and_child
  on parent_and_child.unique_id = triads.parent_and_child_unique_id
