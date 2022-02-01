{% macro fill_node_relationships_csv(this) %}

{% if execute %}

{% set sql %}

INSERT INTO {{ this }} 

    VALUES

    {% set nodes_list = nodes_list %}
    
    {%- for node in graph.nodes.values() -%}
    {%- set outer_loop = loop -%}

        {%- if node.depends_on.nodes|length == 0 -%}

            ('{{ node.name }}','{{ node.unique_id }}','{{ node.resource_type }}',NULL)

        {%- else -%}       

            {%- for parent in node.depends_on.nodes -%}

                ('{{ node.name }}','{{ node.unique_id }}','{{ node.resource_type }}','{{ parent }}'){% if not loop.last %},{% endif %}

            {% endfor -%}
        
        {%- endif %}

        {% if not outer_loop.last %},{% endif %}

    {% endfor -%}

{% endset %}

{% set results = run_query(sql) %}

{% endif %}

{% endmacro %}