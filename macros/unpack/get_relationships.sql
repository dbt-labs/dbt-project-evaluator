{% macro get_relationships(node_type) %}
    {{ return(adapter.dispatch('get_relationships', 'dbt_project_evaluator')(node_type)) }}
{% endmacro %}

{% macro default__get_relationships(node_type) %}

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

        {% set values0 %}

            cast(null as {{ dbt_utils.type_string() }}),
            cast(null as {{ dbt_utils.type_string() }})

        {% endset %}
        {% do values.append(values0) %}

        {%- for node in nodes_list -%}

            {%- if node.depends_on.nodes|length == 0 -%}

                {% set values_line %}
                  cast('{{ node.unique_id }}' as {{ dbt_utils.type_string() }}),cast(NULL as {{ dbt_utils.type_string() }})
                {% endset %}
                {% do values.append(values_line) %}

            {%- else -%}

                {%- for parent in node.depends_on.nodes -%}

                    {% set values_line %}
                      cast('{{ node.unique_id }}' as {{ dbt_utils.type_string() }}),cast('{{ parent }}' as {{ dbt_utils.type_string() }})
                    {% endset %}
                    {% do values.append(values_line) %}

                {% endfor -%}

            {%- endif %}

        {% endfor -%}
    
    {{ return(
        dbt_project_evaluator.select_from_values(
            values = values,
            column_names = [
                'resource_id',
                'direct_parent_id'
            ],
            where_condition='resource_id is not null'
         )
    ) }}

    {% endif %}
  
{% endmacro %}