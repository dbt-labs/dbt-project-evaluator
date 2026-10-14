with all_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where parent_resource_type not in ('exposure', 'metric')
    and child_resource_type not in ('exposure', 'metric')
    and parent_is_excluded = cast(0 as {{ dbt.type_boolean() }})
    and child_is_excluded = cast(0 as {{ dbt.type_boolean() }})
),

-- all parent/child relationships where the parent is BOTH the direct parent of the child and the second level parent of the child 
rejoined as (
    select
        parent_id,
        parent,
        child_id,
        child
    from all_relationships
    group by parent_id, parent, child_id, child
    having (sum(case when distance = 1 then 1 else 0 end) >= 1
        and sum(case when distance = 2 then 1 else 0 end) >= 1)
),

-- resources with only one direct child
single_use_resources as (
    select
        parent_id
    from all_relationships
    where distance = 1
    group by parent_id
    having count(*) = 1
),

-- all cases where one of the parent's direct children (child) is ALSO the direct child of ANOTHER one of the parent's direct childen (parent_and_child)
triad_relationships as (
    select 
        rejoined.parent,
        rejoined.child,
        direct_child.parent as parent_and_child,
        direct_child.parent_id as parent_and_child_id
    from rejoined
    left join all_relationships as direct_child
        on rejoined.child_id = direct_child.child_id
        and direct_child.distance = 1
    left join all_relationships as direct_parent
        on rejoined.parent_id = direct_parent.parent_id
        and direct_parent.distance = 1
    where direct_child.parent_id = direct_parent.child_id
),

-- additionally, only includes cases where the model "in between" the parent and parent_and_child has NO other downstream dependencies
-- Note: when the "in between" model DOES have downstream dependencies, it's possible this DAG choice has been made to avoid duplicated code and as such is OKAY
final as (
    select
        triad_relationships.parent,
        triad_relationships.child,
        triad_relationships.parent_and_child,
        case
            when single_use_resources.parent_id is not null then cast(1 as {{ dbt.type_boolean() }})
            else cast(0 as {{ dbt.type_boolean() }})
        end as is_loop_independent
    from triad_relationships
    left join single_use_resources 
        on triad_relationships.parent_and_child_id = single_use_resources.parent_id
),

final_filtered as (
    select * from final
    where is_loop_independent = cast(1 as {{ dbt.type_boolean() }})
)

select * from final_filtered

{{ filter_exceptions() }}
