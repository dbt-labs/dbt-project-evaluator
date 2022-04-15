with 

tests as (
    select * from {{ ref('int_model_test_summary') }} 
),

final as (

    select 
        resource_name,
        primary_key_tests_per_model
    from tests
    where primary_key_tests_per_model < 2

)

select * from final