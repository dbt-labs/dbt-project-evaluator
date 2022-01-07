{% macro get_dependencies() %}

    {%- set sql -%}
    -- one record for each direct parent & child pair of models in DAG
    with direct_parents as (

    {%- for model in graph.nodes.values() | selectattr("resource_type", "equalto", "model") -%} {# what about sources with no children?? #}
    {%- set outer_loop = loop -%}

        {%- for model_parent in model.refs -%}

        select 
            '{{model.name}}' as model,
            '{{model_parent.0}}' as parent,
            'model' as parent_type
        {% if not outer_loop.last %}union all{% endif %}

        {% endfor -%}

        {%- for source_parent in model.sources -%}

        select 
            '{{model.name}}' as model,
            '{{source_parent.0}}.{{source_parent.1}}' as parent,
            'source' as parent_type
        {% if not outer_loop.last %}union all{% endif %}

        {% endfor -%}

    {%- endfor -%}

    ),

    -- recursive CTE
    all_relationships as (

        -- anchor 
        select 
            parent as parent,
            model as child,
            1 as distance,
            array_construct(parent, child) as path -- snowflake-specific, but helpful for troubleshooting right now
        from direct_parents
        --where parent_type = 'source'

        union all

        -- recursive clause
        select  
            all_relationships.parent as parent,
            direct_parents.model as child, 
            all_relationships.distance+1 as distance,
            array_append(all_relationships.path, direct_parents.model) as path
        from direct_parents
        inner join all_relationships
            on all_relationships.child = direct_parents.parent

    )
    
    select * from all_relationships

    {%- endset -%}

    {% do log(sql, info=true) %}
    
{% endmacro %}