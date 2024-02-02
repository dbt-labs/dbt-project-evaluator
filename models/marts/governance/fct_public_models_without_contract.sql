with 

all_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where not is_excluded
),

final as (

    select 
        resource_name,
        is_public,
        is_contract_enforced
        
    from all_resources
    where 
        is_public 
        and not is_contract_enforced
)

select * from final

{{ filter_exceptions() }}