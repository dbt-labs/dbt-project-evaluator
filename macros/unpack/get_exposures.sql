{% macro get_exposures() %}

    {% if execute %}
    {% set nodes_list = graph.exposures.values() | selectattr('package_name', 'eq', project_name) | list %}
    {% set values = [] %}

    {% for node in nodes_list %}

      {% set values_line %}
      (
        '{{ node.unique_id }}', 
        '{{ node.name }}', 
        '{{ node.resource_type }}', 
        '{{ node.path }}',
        cast('{{ is_not_empty_string(node.description) | trim }}'as boolean), 
        '{{ node.type }}', 
        '{{ node.maturity}}', 
        '{{ node.package_name }}', 
        '{{ node.url }}'
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
              'is_described', 
              'exposure_type', 
              'maturity', 
              'package_name', 
              'url'
            ]
         )
    ) }}

{% endmacro %}