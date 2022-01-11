-- TO DO: only include ENABLED nodes
-- TO DO: exclude models that are part of the audit package
    -- can use package_name attribute in final version
-- TO DO: fix whitespace

-- one record for each node in the DAG (models and sources) and its direct parent
with direct_relationships as (

{%- for model in graph.nodes.values() | selectattr("resource_type", "equalto", "model") -%}
{%- set outer_loop = loop -%}

    {%- if model.depends_on.nodes|length == 0 -%}

    select 
        '{{model.name}}' as node,
        '{{model.unique_id}}' as node_id,
        'model' as node_type,
        NULL as direct_parent_id

    {%- else -%}       

        {%- for model_parent in model.depends_on.nodes -%}

        select
            '{{model.name}}' as node,
            '{{model.unique_id}}' as node_id,
            'model' as node_type,
            '{{model_parent}}' as direct_parent_id
        {% if not loop.last %}union all{% endif %}

        {% endfor -%}
    
    {%- endif %}

    {% if not outer_loop.last %}union all{% endif %}

{% endfor -%}

{%- for source in graph.sources.values() -%}

    {% if loop.first and graph.nodes|length > 0 %}union all{% endif %}
    select 
        '{{source.source_name}}.{{source.name}}' as node,
        '{{source.unique_id}}' as node_id,
        'source' as node_type,
        NULL as direct_parent_id 
    {% if not loop.last %}union all{% endif %}

{% endfor -%}

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
        parent,
        parent_type,
        child,
        distance,
        path
    from all_relationships
)

select * from final
order by parent, distance