with

all_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where not is_excluded

),

final as (

    select
        resource_name

    from all_resources
    where not is_described and resource_type = 'source'

)

select * from final

{{ filter_exceptions() }}