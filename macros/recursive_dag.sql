
{% macro recursive_dag() %}
    {{ return(adapter.dispatch('recursive_dag')()) }}
{% endmacro %}


{% macro default__recursive_dag() %}

{% set debug_snowflake = var('debug_snowflake',false) %}

with recursive direct_relationships as (
    select  
        *
    from {{ ref('int_direct_relationships') }}
    where resource_type <> 'tests'
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
        0 as distance, 
        node_name as path

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
        all_relationships.distance+1 as distance, 
        {{ dbt_utils.concat(["all_relationships.path","' > '","direct_relationships.node_name"]) }} as path

    from direct_relationships
    inner join all_relationships
        on all_relationships.child_id = direct_relationships.direct_parent_id
)

{% endmacro %}





{% macro bigquery__recursive_dag() %}

-- as of Feb 2022 BigQuery doesn't support with recursive in the same way as other DWs
{% set max_depth = var('max_depth_bigquery') %}

with direct_relationships as (
    select  
        *
    from {{ ref('int_direct_relationships') }}
     where resource_type <> 'tests'
)

, cte_0 as (
    select distinct
        node_id as parent_id,
        node_id as child_id,
        0 as distance,
        node_name as path
    from direct_relationships
)

{% for i in range(1,max_depth) %}
, cte_{{i}} as (
    select distinct
        cte_{{i - 1}}.parent_id as parent_id,
        direct_relationships.node_id as child_id,
        cte_{{i - 1}}.distance+1 as distance, 
        concat(cte_{{(i - 1)}}.path,' > ',direct_relationships.node_name) as path

        from direct_relationships
            inner join cte_{{i - 1}}
            on cte_{{i - 1}}.child_id = direct_relationships.direct_parent_id
)
{% endfor %}

, all_relationships_unioned as (
    {% for i in range(max_depth) %}
    select * from cte_{{i}}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

, node_info as (
    select * from {{ ref('stg_all_graph_nodes') }}
)


, all_relationships as (
    select
        parent.node_id as parent_id,
        parent.node_name as parent,
        parent.resource_type as parent_type,
        parent.file_path as parent_file_path,
        child.node_id as child_id,
        child.node_name as child,
        child.resource_type as child_type,
        child.file_path as child_file_path,
        all_relationships_unioned.distance,
        all_relationships_unioned.path
    
    from all_relationships_unioned
    left join node_info as parent
        on all_relationships_unioned.parent_id = parent.node_id
    left join node_info as child
        on all_relationships_unioned.child_id = child.node_id
)

{% endmacro %}