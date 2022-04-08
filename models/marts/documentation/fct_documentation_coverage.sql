with

models as (
    select * from {{ ref('stg_all_graph_resources') }}
    where resource_type = 'model'
),

conversion as (
    select
        resource_id,
        case when is_described then 1.0 else 0 end as is_described_model,
        case when model_type = 'marts' then 1.0 else NULL end as is_marts_model,
        case when is_described and model_type = 'marts' then 1.0 else 0 end as is_described_marts_model

    from models
),

final as (
    select
        current_timestamp as measured_at,
        count(*) as total_models,
        sum(is_described_model) as documented_models,
        round(sum(is_described_model) * 100 / count(*), 2) as documentation_coverage_pct,
        round(sum(is_described_marts_model) * 100 / count(is_marts_model), 2) as marts_documentation_coverage_pct

    from models
    left join conversion using (resource_id)
)

select * from final
