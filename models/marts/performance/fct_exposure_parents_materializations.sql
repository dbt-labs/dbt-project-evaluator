with 

direct_exposure_relationships as (
    select * from {{ ref('int_all_dag_relationships') }}
    where 
        distance = 1
        and child_resource_type = 'exposure'
        and ((
                parent_resource_type = 'model'
                and parent_materialized in ('view', 'ephemeral')
            )
            or (
                parent_resource_type = 'source'
            )
        )
),

final as (

    select 
        parent_package_name as package_name,
        parent_resource_type,
        parent as parent_resource_name,
        child as exposure_name,
        parent_materialized as parent_model_materialization

    from direct_exposure_relationships

)

select * from final

{{ filter_exceptions(this) }}