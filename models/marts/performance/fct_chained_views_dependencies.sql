with all_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where distance <> 0
    and parent_is_excluded = cast(0 as {{ dbt.type_boolean() }})
    and child_is_excluded = cast(0 as {{ dbt.type_boolean() }})
),

final as (
    select
        parent,
        child, -- the model with potentially long run time / compilation time, improve performance by breaking the upstream chain of views
        distance,
        path
    from all_relationships
    where is_dependent_on_chain_of_views = cast(1 as {{ dbt.type_boolean() }})
    and child_resource_type = 'model'
    and distance > {{ var('chained_views_threshold') }}
)

select * from final

{{ filter_exceptions() }}

order by distance desc