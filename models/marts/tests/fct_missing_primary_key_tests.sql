with 

tests as (
    select * from {{ ref('int_model_test_summary') }} 
    where resource_type in
    (
        {% for resource_type in var('enforced_primary_key_node_types') %}'{{ resource_type }}'{% if not loop.last %},{% endif %}
        {% endfor %}
    )
),

final as (

    select 
        *
    from tests
    where not(is_primary_key_tested)

)

select * from final

{{ filter_exceptions(model.name) }}