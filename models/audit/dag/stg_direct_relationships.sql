-- TO DO: only include ENABLED nodes
-- TO DO: exclude models that are part of the audit package
    -- can use package_name attribute in final version
-- TO DO: fix whitespace

-- one record for each node in the DAG (models and sources) and its direct parent
with 

direct_model_relationships as (
    select  
        node,
        node_id,
        resource_type,
        direct_parent_id
    from {{ ref('base__node_relationships')}}
    where resource_type in ('model','snapshot')
    -- and package_name != 'pro-serv-dag-auditing'
),

sources as (
    select * from {{ ref('base__sources')}}
),

direct_source_relationships as (

    select 
        sources.source_name || '.' ||sources.node_name as node,
        sources.unique_id as node_id,
        sources.resource_type as resource_type,
        cast(null as {{ dbt_utils.type_string() }}) as direct_parent_id 
    
    from sources

),

direct_relationships as (

    select * from direct_model_relationships

    union all 

    select * from direct_source_relationships

)

select * from direct_relationships