-- one record for each resource in the graph and its direct parent
with 

all_graph_resources as (
    select
        resource_id,
        resource_name,
        resource_type,
        file_path,
        directory_path, 
        file_name,
        model_type,
        source_name,
        materialized 
    from {{ ref('int_all_graph_resources') }}
),

direct_model_relationships as (
    select  
        resource_id,
        direct_parent_id
    from {{ ref('stg_node_relationships')}}
),

direct_exposure_relationships as (
    select  
        resource_id,
        direct_parent_id
    from {{ ref('stg_exposure_relationships')}}
),

direct_metrics_relationships as (
    select  
        resource_id,
        direct_parent_id
    from {{ ref('stg_metric_relationships')}}
),

-- for all resources in the graph, find their direct parent
direct_relationships as (
    select
        all_graph_resources.*,
        CASE 
            WHEN all_graph_resources.resource_type = 'source' THEN NULL
            WHEN all_graph_resources.resource_type = 'exposure' THEN exposures.direct_parent_id
            WHEN all_graph_resources.resource_type IN ('model', 'snapshot', 'test') THEN models.direct_parent_id
            ELSE NULL
        END AS direct_parent_id
    from all_graph_resources
    left join direct_model_relationships as models
        on all_graph_resources.resource_id = models.resource_id
    left join direct_exposure_relationships as exposures
        on all_graph_resources.resource_id = exposures.resource_id
),

-- getting the materializationof the parent model to be able to track back chains of views
direct_relationships_with_materialization as (
    select
        direct_relationships.*,
        all_graph_resources.materialized as direct_parent_materialized
    from direct_relationships
    left join all_graph_resources
        on direct_relationships.direct_parent_id = all_graph_resources.resource_id
),

final as (
    select
        {{ dbt_utils.surrogate_key(['resource_id', 'direct_parent_id']) }} as unique_id,
        *
    from direct_relationships_with_materialization
)

select * from final
