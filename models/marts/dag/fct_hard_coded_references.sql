-- this model finds cases where a model has hard coded references

with models as (
    select * from {{ ref('int_all_graph_resources') }}
    where resource_type = 'model'
    and not is_excluded
),

final as (
    select
        resource_name as model,
        hard_coded_references
    from models
    where hard_coded_references != ''
)

select * from final

{{ filter_exceptions() }}