-- this model finds cases where a model has raw references

with models as (
    select * from {{ ref('int_all_graph_resources') }}
    where resource_type = 'model'
),

final as (
    select
        resource_name as model,
        raw_references
    from models
    where raw_references is not null
)

select * from final

{{ filter_exceptions(this) }}