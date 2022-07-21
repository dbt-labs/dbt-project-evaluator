with all_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where distance <> 0
),

final as (
    select
        parent,
        child, -- the model with potentially long run time / compilation time, improve performance by breaking the upstream chain of views
        distance,
        path
    from all_relationships
    where is_dependent_on_chain_of_views
    and child_resource_type = 'model'
)

select * from final

{{ filter_exceptions(this) }}

order by distance desc