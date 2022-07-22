with 

tests as (
    select * from {{ ref('int_model_test_summary') }} 
),

final as (

    select 
        resource_name,
        model_type,
        is_primary_key_tested,
        number_of_tests_on_model
    from tests
    where not(is_primary_key_tested)

)

select * from final