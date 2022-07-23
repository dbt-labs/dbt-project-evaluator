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
        materialized,
        source_name 
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
        case 
            when all_graph_resources.resource_type = 'source' then null
            when all_graph_resources.resource_type = 'exposure' then exposures.direct_parent_id
            when all_graph_resources.resource_type = 'metric' then metrics.direct_parent_id
            when all_graph_resources.resource_type in ('model', 'snapshot', 'test') then models.direct_parent_id
            else null
        end as direct_parent_id
    from all_graph_resources
    left join direct_model_relationships as models
        on all_graph_resources.resource_id = models.resource_id
    left join direct_exposure_relationships as exposures
        on all_graph_resources.resource_id = exposures.resource_id
    left join direct_metrics_relationships as metrics
        on all_graph_resources.resource_id = metrics.resource_id
),

final as (
    select
        {{ dbt_utils.surrogate_key(['resource_id', 'direct_parent_id']) }} as unique_id,
        {{ dbt_utils.split_part('direct_parent_id', "'.'", 3) }} as parent_resource_name,
        case 
            when resource_type = 'test'
                    then min({{ dbt_utils.position(dbt_utils.split_part('direct_parent_id', "'.'", 3), 'resource_name') }}) 
                        over (partition by resource_name) = 
                        {{ dbt_utils.position(dbt_utils.split_part('direct_parent_id', "'.'", 3), 'resource_name') }} 
            else false
        end as is_primary_test_relationship,
        *
    from direct_relationships
)

select * from final
