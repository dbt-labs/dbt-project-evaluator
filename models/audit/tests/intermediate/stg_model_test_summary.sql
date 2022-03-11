-- should this be a fct_ model?

with 

all_graph_nodes as (
    select * from {{ ref('stg_all_graph_resources') }}
),

relationships as (
    select * from {{ ref('int_direct_relationships') }}
),

agg_test_relationships as (
    
    select 
        relationships.direct_parent_id, 
        count(distinct relationships.node_id) as tests_per_model 
    from all_graph_nodes
    left join relationships
        on all_graph_nodes.node_id = relationships.node_id
    where all_graph_nodes.resource_type = 'test'
    group by 1
),

final as (
    select 
        all_graph_nodes.node_id, 
        coalesce(agg_test_relationships.tests_per_model, 0) as tests_per_model
    from all_graph_nodes
    left join agg_test_relationships
        on all_graph_nodes.node_id = agg_test_relationships.direct_parent_id
    where all_graph_nodes.resource_type = 'model'
)

select * from final

