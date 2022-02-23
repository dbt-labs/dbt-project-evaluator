with 

untested as (
    select * from {{ ref('stg_model_test_summary') }} where tests_per_model = 0
)

select * from untested