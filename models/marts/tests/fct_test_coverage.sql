with

test_counts as (
    select * from {{ ref('int_model_test_summary') }}
),

conversion as (
    select
        resource_name,
        case when tests_per_model > 0 then 1 else 0 end as is_tested_model,
        case when model_type = 'marts' then 1.0 else NULL end as is_marts_model,
        case when tests_per_model > 0 and model_type = 'marts' then 1.0 else 0 end as is_tested_marts_model

    from test_counts
),

final as (
    select
        current_timestamp as measured_at,
        count(*) as total_models,
        sum(tests_per_model) as total_tests,
        sum(is_tested_model) as tested_models,
        round(sum(is_tested_model) * 100 / count(*), 2) as test_coverage_pct,
        round(sum(is_tested_marts_model) * 100 / count(is_marts_model), 2) as marts_test_coverage_pct,
        round(sum(tests_per_model) / count(*), 4) as test_to_model_ratio

    from test_counts
    left join conversion
    on test_counts.resource_name = conversion.resource_name
)

select * from final