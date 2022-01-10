{% macro get_dependencies() %}

    {%- set sql -%}
    -- one record for each node in the DAG (models and sources) and its direct parent
    with direct_relationships as (

    {%- for model in graph.nodes.values() | selectattr("resource_type", "equalto", "model") -%}
    {%- set outer_loop = loop -%}

        {%- if model.depends_on.nodes|length == 0 -%}

        select 
            '{{model.name}}' as model,
            NULL as direct_parent,
            NULL as direct_parent_type  {# if this field still useful? if not could simply by looping through depends_on.nodes instead of refs & sources seperately #}

        {%- else -%}       

            {%- for model_parent in model.refs -%}

            select 
                '{{model.name}}' as model,
                '{{model_parent.0}}' as direct_parent,
                'model' as direct_parent_type
            {% if not loop.last %}union all{% endif %}

            {% endfor -%}

            {%- for source_parent in model.sources -%}

            {% if loop.first and model.refs|length > 0 %}union all{% endif %}
            select 
                '{{model.name}}' as model,
                '{{source_parent.0}}.{{source_parent.1}}' as direct_parent,
                'source' as direct_parent_type
            {% if not loop.last %}union all{% endif %}

            {% endfor -%}
        
        {%- endif -%}

        {% if not outer_loop.last %}union all{% endif %}

    {% endfor -%}

    {%- for source in graph.sources.values() -%}

        {% if loop.first and graph.nodes|length > 0 %}union all{% endif %}
        select 
            '{{source.source_name}}.{{source.name}}' as model,
            NULL as direct_parent,
            NULL as direct_parent_type 
        {% if not loop.last %}union all{% endif %}
    
    {% endfor -%}

    ),

    -- recursive CTE
    -- one record for every root node and each of its downstream children (including itself)
    all_relationships as (

        -- anchor 
        select distinct
            model as parent,
            model as child,
            0 as distance,
            array_construct(child) as path {# snowflake-specific, but helpful for troubleshooting right now #}
        from direct_relationships
        where direct_parent is null

        union all

        -- recursive clause
        select  
            all_relationships.parent as parent,
            direct_relationships.model as child, 
            all_relationships.distance+1 as distance,
            array_append(all_relationships.path, direct_relationships.model) as path
        from direct_relationships
        inner join all_relationships
            on all_relationships.child = direct_relationships.direct_parent

    )
    
    select * from all_relationships
    order by parent, distance

    {%- endset -%}

    {% do log(sql, info=true) %}
    
{% endmacro %}