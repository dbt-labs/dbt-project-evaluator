with all_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
),

-- all parent/child relationships where the parent node is BOTH the direct parent of the child and the second level parent of the child 
rejoined as (
    select
        parent,
        child,
        sum(case when distance = 1 then 1 else 0 end) as num_1_distance_paths,
        sum(case when distance = 2 then 1 else 0 end) as num_2_distance_paths
    from all_relationships
    group by 1, 2
    having (num_1_distance_paths >= 1 and num_2_distance_paths >= 1)
),

-- nodes with only one direct child
single_use_nodes as (
    select
        parent
    from all_relationships
    where distance = 1
    group by 1
    having count(*) = 1
),

-- all cases where one of the parent node's direct children (direct_child_1) is ALSO the direct child of ANOTHER one of the parent node's direct childen (direct_child_2)
three_node_relationships as (
    select 
        rejoined.parent,
        rejoined.child as direct_child_1,
        direct_child.parent as direct_child_2
    from rejoined
    left join all_relationships as direct_child
        on rejoined.child = direct_child.child
        and direct_child.distance = 1
    left join all_relationships as direct_parent
        on rejoined.parent = direct_parent.parent
        and direct_parent.distance = 1
    where direct_child.parent = direct_parent.child
),

-- additionally, only includes cases where the model "in between" the parent node and direct_child_1 has NO other downstream dependencies
-- Note: when the "in between" model DOES have downstream dependencies, it's possible this DAG choice has been made to avoid duplicated code and as such is OKAY
final as (
    select
        three_node_relationships.*
    from three_node_relationships
    inner join single_use_nodes 
        on three_node_relationships.direct_child_2 = single_use_nodes.parent
)

select * from final