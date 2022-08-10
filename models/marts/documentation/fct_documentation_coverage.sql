with

models as (
    select * from {{ ref('int_all_graph_resources') }}
    where resource_type = 'model'
),

conversion as (
    select
        resource_id,
        case when is_described then 1 else 0 end as is_described_model,
        {% for model_type in var('model_types') %}
            case when model_type = '{{ model_type }}' then 1.0 else NULL end as is_{{ model_type }}_model,
            case when is_described and model_type = '{{ model_type }}' then 1.0 else 0 end as is_described_{{ model_type }}_model{% if not loop.last %},{% endif %}
        {% endfor %}

    from models
),

final as (
    select
        current_timestamp as measured_at,
        count(*) as total_models,
        sum(is_described_model) as documented_models,
        round(sum(is_described_model) * 100.0 / count(*), 2) as documentation_coverage_pct,
        {% for model_type in var('model_types') %}
            round(sum(is_described_{{ model_type }}_model) * 100 / count(is_{{ model_type }}_model), 2) as {{ model_type }}_documentation_coverage_pct{% if not loop.last %},{% endif %}
        {% endfor %}

    from models
    left join conversion
    on models.resource_id = conversion.resource_id
)

select * from final
