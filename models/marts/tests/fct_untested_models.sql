with

tests as (
    select * from {{ ref('int_model_test_summary') }}
),

final as (

    select
        resource_name,
        model_type
        
    from tests
    where tests_per_model = 0

)

select * from final
