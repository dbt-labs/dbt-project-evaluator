with

all_resources as (
    select * from {{ ref('int_all_graph_resources') }}

),

final as (

    select
        resource_name,
        model_type

    from all_resources
    where not is_described and resource_type = 'model'

)

select * from final

{{ filter_exceptions(this) }}