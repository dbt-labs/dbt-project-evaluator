with 

all_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where is_excluded = cast(0 as {{ dbt.type_boolean() }})
),

final as (

    select 
        resource_name,
        is_public,
        is_contract_enforced
        
    from all_resources
    where 
        is_public = cast(1 as {{ dbt.type_boolean() }})
        and is_contract_enforced = cast(0 as {{ dbt.type_boolean() }})
)

select * from final

{{ filter_exceptions() }}