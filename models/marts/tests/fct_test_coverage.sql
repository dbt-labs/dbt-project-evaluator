with

test_counts as (
    select * from {{ ref('int_model_test_summary') }}
),

conversion as (
    select
        resource_name,
        case when number_of_tests_on_model > 0 then 1 else 0 end as is_tested_model,
        {% for model_type in var('model_types') %}
            case when model_type = '{{ model_type }}' then 1.0 else NULL end as is_{{ model_type }}_model,
            case when number_of_tests_on_model > 0 and model_type = '{{ model_type }}' then 1.0 else 0 end as is_tested_{{ model_type }}_model{% if not loop.last %},{% endif %}
        {% endfor %}

    from test_counts
),

final as (
    select
        current_timestamp as measured_at,
        count(*) as total_models,
        sum(number_of_tests_on_model) as total_tests,
        sum(is_tested_model) as tested_models,
        round(sum(is_tested_model) * 100.0 / count(*), 2) as test_coverage_pct,
        {% for model_type in var('model_types') %}
            round(sum(is_tested_{{ model_type }}_model) * 100.0 / count(is_{{ model_type }}_model), 2) as {{ model_type }}_test_coverage_pct,
        {% endfor %}
        round(sum(number_of_tests_on_model) * 1.0 / count(*), 4) as test_to_model_ratio

    from test_counts
    left join conversion
    on test_counts.resource_name = conversion.resource_name
)

select * from final