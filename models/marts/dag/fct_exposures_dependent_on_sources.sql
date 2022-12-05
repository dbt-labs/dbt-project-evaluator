with 

direct_exposure_relationships as (
    
    select * from {{ ref('int_all_dag_relationships') }}
    where 
        distance = 1
        and child_resource_type = 'exposure'
        and parent_resource_type = 'source'
),

final as (

    select 
        parent as parent_source_name,
        child as exposure_name

    from direct_exposure_relationships

)

select * from final

{{ filter_exceptions(this) }}