with 

models as (
    select * from {{ ref('stg_all_graph_resources') }}
    where resource_type = 'model' 
), 

final as (
    select 
        current_timestamp as measured_at, 
        count(*) as total_models,
        sum(case when is_described then 1 else 0 end) as documented_models,
        round(sum(case when is_described then 1 else 0 end) * 100 / count(*), 2) as documentation_coverage_pct
    from models
)

select * from final