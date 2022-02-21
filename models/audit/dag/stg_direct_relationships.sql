-- TO DO: only include ENABLED nodes
-- TO DO: exclude models that are part of the audit package
    -- can use package_name attribute in final version
-- TO DO: fix whitespace

-- one record for each node in the DAG (models and sources) and its direct parent
with 

all_dag_nodes as (
    select * from {{ ref('stg_all_dag_nodes') }}
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

-- for all nodes in the DAG, find their direct parent
direct_relationships as (
    select
        all_dag_nodes.node_id,
        CASE 
            WHEN resource_type = 'source' THEN NULL
            WHEN resource_type IN ('model', 'snapshot') THEN models.direct_parent_id
            WHEN resource_type = 'exposure' THEN exposures.direct_parent_id
            ELSE NULL
        END AS direct_parent_id
    from all_dag_nodes
    left join direct_model_relationships as models
        on all_dag_nodes.node_id = models.node_id
    left join direct_exposure_relationships as exposures
        on all_dag_nodes.node_id = exposures.node_id
)

select * from direct_relationships