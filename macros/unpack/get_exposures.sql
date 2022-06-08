{% macro get_exposures() %}
    {{ return(adapter.dispatch('get_exposures', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__get_exposures() %}

    {% if execute %}
    {% set nodes_list = graph.exposures.values() %}
    {% set values = [] %}

    {% for node in nodes_list %}

      {% set values_line %}

        '{{ node.unique_id }}',
        '{{ node.name }}',
        '{{ node.resource_type }}',
        '{{ node.original_file_path }}',
        cast('{{ dbt_project_evaluator.is_not_empty_string(node.description) | trim }}'as boolean),
        '{{ node.type }}',
        '{{ node.maturity}}',
        '{{ node.package_name }}',
        '{{ node.url }}'
      
      {% endset %}
      {% do values.append(values_line) %}

    {% endfor %}
    {% endif %}

    {{ return(
        dbt_project_evaluator.select_from_values(
            values = values,
            column_names = [
              'unique_id', 
              'name', 
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