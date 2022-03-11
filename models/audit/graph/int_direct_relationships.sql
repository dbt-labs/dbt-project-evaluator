-- TO DO: exclude models that are part of the audit package
    -- can use package_name attribute in final version
-- TO DO: fix whitespace

-- one record for each node in the graph and its direct parent
with 

all_graph_nodes as (
    select
        node_id,
        node_name,
        resource_type,
        file_path,
        model_type 
    from {{ ref('stg_all_graph_resources') }}
),

direct_model_relationships as (
    select  
        node_id,
        direct_parent_id
    from {{ ref('base__node_relationships')}}
),

direct_exposure_relationships as (
    select  
        node_id,
        direct_parent_id
    from {{ ref('base__exposure_relationships')}}
),

direct_metrics_relationships as (
    select  
        node_id,
        direct_parent_id
    from {{ ref('base__metric_relationships')}}
),

-- for all nodes in the graph, find their direct parent
direct_relationships as (
    select
        all_graph_nodes.*,
        CASE 
            WHEN all_graph_nodes.resource_type = 'source' THEN NULL
            WHEN all_graph_nodes.resource_type = 'exposure' THEN exposures.direct_parent_id
            WHEN all_graph_nodes.resource_type IN ('model', 'snapshot', 'test') THEN models.direct_parent_id
            ELSE NULL
        END AS direct_parent_id
    from all_graph_nodes
    left join direct_model_relationships as models
        on all_graph_nodes.node_id = models.node_id
    left join direct_exposure_relationships as exposures
        on all_graph_nodes.node_id = exposures.node_id
)

select * from direct_relationships