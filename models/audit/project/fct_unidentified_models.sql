with models as (

    select * from {{ ref('stg_all_graph_resources') }}

),

final as (

    select
        file_path,
        resource_id,
        resource_name
    from models
    where model_type = 'other'

)

select * from final
