with 

direct_exposure_relationships as (
    select * from {{ ref('int_all_dag_relationships') }}
    where 
        distance = 1
        and child_resource_type = 'exposure'
        and not (
                parent_resource_type = 'model'
                and parent_is_public
            )
        and not parent_is_excluded
),

final as (

    select 
        child as exposure_name,
        parent as parent_resource_name,
        parent_access,
        parent_resource_type

    from direct_exposure_relationships

)

select * from final

{{ filter_exceptions() }}