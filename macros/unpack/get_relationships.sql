{% macro get_relationships(node_type) %}

    {% if execute %}

        {% if node_type == 'nodes' %}
            {% set nodes_list = graph.nodes.values() %}   
        {% elif node_type == 'exposures' %}
            {% set nodes_list = graph.exposures.values() %}
        {% elif node_type == 'metrics' %}
            {% set nodes_list = graph.metrics.values() %}
        {% else %}
            {{ exceptions.raise_compiler_error("node_type needs to be either nodes, exposures or metrics, got " ~ node_type) }}
        {% endif %}
        
        {% set values = [] %}

        {%- for node in nodes_list -%}

            {%- if node.depends_on.nodes|length == 0 -%}

                {% set values_line %}
                  ('{{ node.unique_id }}',NULL)
                {% endset %}
                {% do values.append(values_line) %}

            {%- else -%}       

                {%- for parent in node.depends_on.nodes -%}

                    {% set values_line %}
                    ('{{ node.unique_id }}','{{ parent }}')
                    {% endset %}
                    {% do values.append(values_line) %}

                {% endfor -%}

            {%- endif %}

        {% endfor -%}
    
    {{ return(
        select_from_values(
            values = values,
            column_names = [
                'resource_id',
                'direct_parent_id'
            ]
         )
    ) }}

    {% endif %}
  
{% endmacro %}