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
        '{{model.unique_id.split(".")[0]}}' as node_type,
        NULL as direct_parent_id

    {%- else -%}       

        {%- for model_parent in model.depends_on.nodes -%}

        select
            '{{model.name}}' as node,
            '{{model.unique_id}}' as node_id,
            '{{model.unique_id.split(".")[0]}}' as node_type,
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
        '{{source.unique_id.split(".")[0]}}' as node_type,
        NULL as direct_parent_id 
    {% if not loop.last %}union all{% endif %}

{% endfor -%}

)

select * from direct_relationships