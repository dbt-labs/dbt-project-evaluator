with 

all_graph_resources as (
    select * from {{ ref('stg_all_graph_resources') }}
),

relationships as (
    select * from {{ ref('int_direct_relationships') }}
),

agg_test_relationships as (
    
    select 
        relationships.direct_parent_id, 
        count(distinct case when all_graph_resources.is_unique_test or all_graph_resources.is_not_null_test then relationships.resource_id else null end) primary_key_tests_per_model,
        count(distinct relationships.resource_id) as tests_per_model 
    from all_graph_resources
    left join relationships
        on all_graph_resources.resource_id = relationships.resource_id
    where all_graph_resources.resource_type = 'test'
    group by 1
),

final as (
    select 
        all_graph_resources.resource_name, 
        coalesce(agg_test_relationships.primary_key_tests_per_model, 0) as primary_key_tests_per_model,
        coalesce(agg_test_relationships.tests_per_model, 0) as tests_per_model
    from all_graph_resources
    left join agg_test_relationships
        on all_graph_resources.resource_id = agg_test_relationships.direct_parent_id
    where all_graph_resources.resource_type = 'model'
)

select * from final
