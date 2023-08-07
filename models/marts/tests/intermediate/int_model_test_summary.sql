with 

all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where not is_excluded
),

relationships as (
    select * from {{ ref('int_direct_relationships') }}
),

count_column_tests as (
    
    select 
        relationships.direct_parent_id, 
        all_graph_resources.column_name,
        {%- for test_set in var('primary_key_test_macros') %}
            {%- set outer_loop = loop -%}
        count(distinct case when 
                {%- for test in test_set %} 
                all_graph_resources.is_{{ test.split('.')[1] }} {%- if not loop.last %} or {% endif %} 
                {%- endfor %}
            then relationships.resource_id else null end
        ) as primary_key_method_{{ outer_loop.index }}_count,
        {%- endfor %}
        count(distinct relationships.resource_id) as tests_count
    from all_graph_resources
    left join relationships
        on all_graph_resources.resource_id = relationships.resource_id
    where all_graph_resources.resource_type = 'test'
    and relationships.is_primary_test_relationship
    group by 1,2
),

agg_test_relationships as (

    select 
        direct_parent_id, 
        sum(case 
                when (
                    {%- for test_set in var('primary_key_test_macros') %}
                        {%- set compare_value = test_set | length %}
                    primary_key_method_{{ loop.index }}_count = {{ compare_value}}
                        {%- if not loop.last %} or {% endif %}
                    {%- endfor %} 
                ) then 1 
                else 0 
            end
        ) >= 1 as is_primary_key_tested,
        sum(tests_count) as number_of_tests_on_model
    from count_column_tests
    group by 1

),

final as (
    select 
        all_graph_resources.resource_name, 
        all_graph_resources.model_type,
        coalesce(agg_test_relationships.is_primary_key_tested, FALSE) as is_primary_key_tested,
        coalesce(agg_test_relationships.number_of_tests_on_model, 0) as number_of_tests_on_model
    from all_graph_resources
    left join agg_test_relationships
        on all_graph_resources.resource_id = agg_test_relationships.direct_parent_id
    where all_graph_resources.resource_type = 'model'
)

select * from final
