with

all_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where is_excluded = cast(0 as {{ dbt.type_boolean() }})

),

final as (

    select
        resource_name,
        model_type

    from all_resources
    where is_described = cast(0 as {{ dbt.type_boolean() }}) and resource_type = 'model'

)

select * from final

{{ filter_exceptions() }}