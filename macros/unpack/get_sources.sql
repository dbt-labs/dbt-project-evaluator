{% macro get_sources() %}

    {% if execute %}
    {% set nodes_list = graph.sources.values() %}
    {% set values = [] %}

    {% for node in nodes_list %}

         {% set values_line %}
            (
              '{{ node.unique_id }}', 
              '{{ node.name }}', 
              '{{ node.alias }}', 
              '{{ node.resource_type }}', 
              '{{ node.source_name }}', 
              cast('{{ is_not_empty_string(node.source_description) | trim }}' as boolean), 
              cast('{{ is_not_empty_string(node.description) | trim }}' as boolean), 
              cast('{{ node.config.enabled }}' as boolean), 
              '{{ node.loaded_at_field}}', 
              '{{ node.database }}', 
              '{{ node.schema }}', 
              '{{ node.package_name }}', 
              '{{ node.loader }}', 
              '{{ node.identifier }}'
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
              'alias',
              'resource_type',
              'source_name',
              'is_source_described',
              'is_described',
              'is_enabled',
              'loaded_at_field',
              'database',
              'schema',
              'package_name',
              'loader',
              'identifier' 
            ]
         )
    ) }}
 
{% endmacro %}