{% set debug_snowflake = var('debug_snowflake',false) %}

with recursive direct_relationships as (
    select  
        *
    from {{ ref('int_direct_relationships') }}
    where resource_type <> 'test'
),

-- should this be a fct_ model?

-- recursive CTE
-- one record for every node and each of its downstream children (including itself)
all_relationships as (
    -- anchor 
    select distinct
        node_id as parent_id,
        node_name as parent,
        resource_type as parent_type,
        file_path as parent_file_path,
        node_id as child_id,
        node_name as child,
        resource_type as child_type,
        file_path as child_file_path,
        0 as distance

        {% if debug_snowflake %}
        , array_construct(child) as path -- snowflake-specific, but helpful for troubleshooting  
        {% endif %}

    from direct_relationships
    -- where direct_parent is null {# optional lever to change filtering of anchor clause to only include root nodes #}
    
    union all

    -- recursive clause
    select  
        all_relationships.parent_id as parent_id,
        all_relationships.parent as parent,
        all_relationships.parent_type as parent_type,
        all_relationships.parent_file_path as parent_file_path,
        direct_relationships.node_id as child_id,
        direct_relationships.node_name as child,
        direct_relationships.resource_type as child_type,
        direct_relationships.file_path as child_file_path,
        all_relationships.distance+1 as distance

        {% if debug_snowflake %}
        , array_append(all_relationships.path, direct_relationships.node) as path
        {% endif %}

    from direct_relationships
    inner join all_relationships
        on all_relationships.child_id = direct_relationships.direct_parent_id
)

select * from all_relationships
order by parent, distance