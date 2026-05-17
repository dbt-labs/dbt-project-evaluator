with

all_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where is_excluded = cast(0 as {{ dbt.type_boolean() }})

),

final as (

    select distinct
        resource_name

    from all_resources
    where is_freshness_enabled = cast(0 as {{ dbt.type_boolean() }}) and resource_type = 'source'

)

select * from final

{{ filter_exceptions() }}