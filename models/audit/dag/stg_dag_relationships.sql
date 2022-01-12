-- TO DO: only include ENABLED nodes
-- TO DO: exclude models that are part of the audit package
    -- can use package_name attribute in final version
-- TO DO: fix whitespace

-- one record for each node in the DAG (models and sources) and its direct parent
with 

models as (
    select * from {{ ref('base__nodes')}}
    where resource_type = 'model'
    -- and enabled = true
    -- and package_name != 'pro-serv-dag-auditing'
),

sources as (
    select * from {{ ref('base__sources')}}
),

direct_model_relationships as (
    
    select 
        models.node_name as node, 
        models.unique_id as node_id,
        models.resource_type as node_type,
        parents.value as direct_parent_id 
        
    from models,
    lateral flatten(depends_on:nodes, outer => true) as parents

),

direct_source_relationships as (

    select 
        sources.source_name || '.' ||sources.node_name as node, 
        sources.unique_id as node_id,
        sources.resource_type as node_type,
        null as direct_parent_id 
    
    from sources

),

direct_relationships as (

    select * from direct_model_relationships

    union all 

    select * from direct_source_relationships

),

-- recursive CTE
-- one record for every node and each of its downstream children (including itself)
all_relationships as (
    -- anchor 
    select distinct
        node as parent,
        node_id as parent_id,
        node_type as parent_type,
        node as child,
        node_id as child_id,
        0 as distance,
        array_construct(child) as path {# snowflake-specific, but helpful for troubleshooting right now #}
    from direct_relationships
    -- where direct_parent is null {# optional lever to change filtering of anchor clause to only include root nodes #}
    
    union all

    -- recursive clause
    select  
        all_relationships.parent as parent,
        all_relationships.parent_id as parent_id,
        all_relationships.parent_type as parent_type,
        direct_relationships.node as child, 
        direct_relationships.node_id as child_id,
        all_relationships.distance+1 as distance,
        array_append(all_relationships.path, direct_relationships.node) as path
    from direct_relationships
    inner join all_relationships
        on all_relationships.child_id = direct_relationships.direct_parent_id
),

final as (
    select
        {{
            dbt_utils.surrogate_key([
                'parent',
                'parent_type',
                'child',
                'distance',
                'path'
            ])
        }} as unique_id,
        parent,
        parent_type,
        child,
        distance,
        path
    from all_relationships
)

select * from final
order by parent, distance