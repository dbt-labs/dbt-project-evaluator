{% macro get_nodes() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() %}
    {% set values = [] %}

    {% for node in nodes_list %}

          {% set values_line %}
            (
              '{{ node.unique_id }}', 
              '{{ node.name }}', 
              '{{ node.resource_type }}', 
              '{{ node.path }}',
              cast('{{ node.config.enabled | trim }}' as boolean), 
              '{{ node.config.materialized }}', 
              '{{ node.config.on_schema_change}}', 
              '{{ node.database }}', 
              '{{ node.schema }}', 
              '{{ node.package_name }}', 
              '{{ node.alias }}',
              cast('{{ is_not_empty_string(node.description) | trim }}' as boolean)
            )
        {% endset %}
        {% do values.append(values_line) %}

    {% endfor %}
    {% endif %}

    {{ return(
        select_from_values(
            values = values,
            column_names = [
              'unique_id', 
              'name', 
              'resource_type', 
              'file_path',
              'is_enabled', 
              'materialized', 
              'on_schema_change', 
              'database', 
              'schema', 
              'package_name', 
              'alias',
              'is_described'
            ]
         )
    ) }}

{% endmacro %}