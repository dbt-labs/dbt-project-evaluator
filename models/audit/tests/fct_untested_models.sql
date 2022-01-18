with 

untested as (
    select * from {{ ref('stg_model_test_summary') }} where total_tests_applied = 0
)

select * from untested