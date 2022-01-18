with 

test_counts as (
    select * from {{ ref('stg_model_test_summary') }}
), 

final as (
    select 
        current_timestamp as measured_at, 
        count(*) as total_models,
        sum(total_tests_applied) as total_tests,
        sum(case when total_tests_applied > 0 then 1 else 0 end) as tested_models,
        round(tested_models / total_models, 4) * 100 as test_coverage, 
        round(total_tests / total_models, 4)  as test_to_model_ratio 
    from test_counts
)

select * from final
