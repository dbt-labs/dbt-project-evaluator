{% macro get_nodes() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() | selectattr('package_name', 'eq', project_name) | list %}
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
              '{{ node.alias }}'
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
              'node_name', 
              'resource_type', 
              'file_path',
              'is_enabled', 
              'materialized', 
              'on_schema_change', 
              'database', 
              'schema', 
              'package_name', 
              'alias'
            ]
         )
    ) }}

{% endmacro %}