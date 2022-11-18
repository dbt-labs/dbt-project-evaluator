with 

all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
),

relationships as (
    select * from {{ ref('int_direct_relationships') }}
),

count_column_tests as (
    
    select 
        relationships.direct_parent_id, 
        all_graph_resources.column_name,
        count(distinct case when all_graph_resources.is_unique_test or all_graph_resources.is_not_null_test then relationships.resource_id else null end) unique_and_not_null_test_count,
        count(distinct case when all_graph_resources.is_unique_combo_test then relationships.resource_id else null end) unique_combo_test_count,
        count(distinct case when all_graph_resources.is_pk_constraint_test then relationships.resource_id else null end) pk_constraint_test_count,
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
                when unique_and_not_null_test_count = 2 
                    or unique_combo_test_count = 1 
                    or pk_constraint_test_count = 1 
                        then 1 
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
