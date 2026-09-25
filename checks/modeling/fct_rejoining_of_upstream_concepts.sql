-- A -> B -> C where C also selects from A directly and B is only used by C.
-- B can usually be folded into C (as a CTE) to simplify the DAG.
-- unique_id is the intermediate model (B), which is the one to refactor.
with nodes as (
    select node.unique_id, node.name, node.version
    from {{ info_schema('graph_nodes') }} node
    where {{ evaluator_check_in_scope('node') }}
      and node.resource_type not in ('exposure', 'metric', 'test', 'data_test', 'unit_test')
),

direct_edges as (
    select distinct edge.parent_unique_id, edge.child_unique_id
    from {{ info_schema('edges') }} edge
    join nodes parent on parent.unique_id = edge.parent_unique_id
    join nodes child on child.unique_id = edge.child_unique_id
),

single_use as (
    select parent_unique_id
    from direct_edges
    group by parent_unique_id
    having count(*) = 1
),

triads as (
    select first_hop.parent_unique_id,
           first_hop.child_unique_id as parent_and_child_unique_id,
           second_hop.child_unique_id
    from direct_edges first_hop
    join single_use on single_use.parent_unique_id = first_hop.child_unique_id
    join direct_edges second_hop on second_hop.parent_unique_id = first_hop.child_unique_id
    join direct_edges shortcut
      on shortcut.parent_unique_id = first_hop.parent_unique_id
     and shortcut.child_unique_id = second_hop.child_unique_id
)

select parent_and_child.unique_id,
       parent.name as parent,
       parent_and_child.name as parent_and_child,
       case
           when child.version is null then child.name
           else child.name || '.v' || cast(child.version as varchar)
       end as child
from triads
join nodes parent on parent.unique_id = triads.parent_unique_id
join nodes parent_and_child on parent_and_child.unique_id = triads.parent_and_child_unique_id
join nodes child on child.unique_id = triads.child_unique_id
