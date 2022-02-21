{% set debug_snowflake = var('debug_snowflake',false) %}

with recursive direct_relationships as (
    select  
        *
    from {{ ref('stg_direct_relationships') }}
),

-- should this be a fct_ model?

-- recursive CTE
-- one record for every node and each of its downstream children (including itself)
all_relationships as (
    -- anchor 
    select distinct
        node_id as parent_id,
        node_id as child_id,
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
        direct_relationships.node_id as child_id,
        all_relationships.distance+1 as distance

        {% if debug_snowflake %}
        , array_append(all_relationships.path, direct_relationships.node) as path
        {% endif %}

    from direct_relationships
    inner join all_relationships
        on all_relationships.child_id = direct_relationships.direct_parent_id
),

node_info as (
    select * from {{ ref('stg_all_dag_nodes') }}
),

final as (
    select
        parent.node_name as parent,
        parent.resource_type as parent_type,
        parent.file_path as parent_file_path,
        child.node_name as child,
        child.resource_type as child_type,
        child.file_path as child_file_path,
        all_relationships.distance

        {% if debug_snowflake %}
        , all_relationships.path
        {% endif %}

    from all_relationships
    left join node_info as parent
        on all_relationships.parent_id = parent.node_id
    left join node_info as child
        on all_relationships.child_id = child.node_id
)

select * from final
order by parent, distance