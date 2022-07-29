with all_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where parent_resource_type not in ('exposures', 'metrics')
    and child_resource_type not in ('exposures', 'metrics')
),

-- all parent/child relationships where the parent is BOTH the direct parent of the child and the second level parent of the child 
rejoined as (
    select
        parent,
        child
    from all_relationships
    group by 1, 2
    having (sum(case when distance = 1 then 1 else 0 end) >= 1 
        and sum(case when distance = 2 then 1 else 0 end) >= 1)
),

-- resources with only one direct child
single_use_resources as (
    select
        parent
    from all_relationships
    where distance = 1
    group by 1
    having count(*) = 1
),

-- all cases where one of the parent's direct children (child) is ALSO the direct child of ANOTHER one of the parent's direct childen (parent_and_child)
triad_relationships as (
    select 
        rejoined.parent,
        rejoined.child as child,
        direct_child.parent as parent_and_child
    from rejoined
    left join all_relationships as direct_child
        on rejoined.child = direct_child.child
        and direct_child.distance = 1
    left join all_relationships as direct_parent
        on rejoined.parent = direct_parent.parent
        and direct_parent.distance = 1
    where direct_child.parent = direct_parent.child
),

-- additionally, only includes cases where the model "in between" the parent and parent_and_child has NO other downstream dependencies
-- Note: when the "in between" model DOES have downstream dependencies, it's possible this DAG choice has been made to avoid duplicated code and as such is OKAY
final as (
    select
        triad_relationships.*,
        case 
            when single_use_resources.parent is not null then true 
            else false
        end as is_loop_independent
    from triad_relationships
    left join single_use_resources 
        on triad_relationships.parent_and_child = single_use_resources.parent
),

final_filtered as (
    select * from final
    where is_loop_independent
)

select * from final_filtered

{{ filter_exceptions(this) }}