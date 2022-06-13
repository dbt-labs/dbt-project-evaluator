with 

direct_exposure_relationships as (
    select * from {{ ref('int_all_dag_relationships') }}
    where 
        distance = 1
        and child_resource_type = 'exposure'
        and parent_resource_type = 'model'
        and parent_materialized not in ('table', 'incremental')
),

final as (

    select 
        parent as model_name,
        child as exposure_name,
        parent_materialized as parent_model_materialization,
        parent_model_type as parent_model_type

    
    from direct_exposure_relationships

)

select * from final