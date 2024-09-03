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
        sum(case
                when all_graph_resources.is_test_unique
                then 1
                else 0
            end
         ) as test_unique_count,
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

count_column_constraints as (

    select
        node_unique_id as direct_parent_id,
        name as column_name,
        case
            when has_not_null_constraint
            then 1
            else 0
        end as constraint_not_null_count,
        constraints_count
    from {{ ref('base_node_columns') }}

),

combine_column_counts as (

    select
        count_column_tests.*,
        count_column_tests.test_unique_count + count_column_constraints.constraint_not_null_count as primary_key_mixed_method_count,
        count_column_constraints.constraints_count
    from count_column_tests
    left join count_column_constraints
        on count_column_tests.direct_parent_id = count_column_constraints.direct_parent_id
        and count_column_tests.column_name = count_column_constraints.column_name

),

agg_test_relationships as (

    select 
        direct_parent_id, 
        cast(sum(case 
                when (
                    {%- for test_set in var('primary_key_test_macros') %}
                        {%- set compare_value = test_set | length %}
                    primary_key_method_{{ loop.index }}_count >= {{ compare_value}}
                        or
                    {%- endfor %}
                    primary_key_mixed_method_count >= 2
                ) then 1 
                else 0 
            end
        ) >= 1 as {{ dbt.type_boolean() }}) as is_primary_key_tested,
        cast(sum(tests_count) as {{ dbt.type_int()}}) as number_of_tests_on_model,
        cast(sum(constraints_count) as {{ dbt.type_int()}}) as number_of_constraints_on_model
    from combine_column_counts
    group by 1

),

final as (
    select 
        all_graph_resources.resource_name,
        all_graph_resources.resource_type,
        all_graph_resources.model_type,
        cast(coalesce(agg_test_relationships.is_primary_key_tested, FALSE) as {{ dbt.type_boolean()}}) as is_primary_key_tested,
        cast(coalesce(agg_test_relationships.number_of_tests_on_model, 0) as {{ dbt.type_int()}}) as number_of_tests_on_model,
        cast(coalesce(agg_test_relationships.number_of_constraints_on_model, 0) as {{ dbt.type_int()}}) as number_of_constraints_on_model
    from all_graph_resources
    left join agg_test_relationships
        on all_graph_resources.resource_id = agg_test_relationships.direct_parent_id
    where
        all_graph_resources.resource_type in ('model', 'seed', 'source', 'snapshot')
)

select * from final
