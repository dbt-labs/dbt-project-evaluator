with 

test_counts as (
    select * from {{ ref('int_model_test_summary') }}
), 

final as (
    select 
        current_timestamp as measured_at, 
        count(*) as total_models,
        sum(tests_per_model) as total_tests,
        sum(case when tests_per_model > 0 then 1 else 0 end) as tested_models,
        round(sum(case when tests_per_model > 0 then 1.0 else 0 end) * 100 / count(*), 2) as test_coverage_pct, 
        round(sum(tests_per_model) / count(*), 4)  as test_to_model_ratio 
    from test_counts
)

select * from final