{% set query %}
with 

tests as (
    select * from {{ ref('int_model_test_summary') }} 
),

final as (

    select 
        *
    from tests
    where not(is_primary_key_tested)

)

select * from final
{% endset %}

{{ query }}
{{ filter_exceptions(this, query) }}