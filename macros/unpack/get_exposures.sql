{% macro get_exposures() %}
    {{ return(adapter.dispatch('get_exposures', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__get_exposures() %}

    {% if execute %}
    {% set nodes_list = graph.exposures.values() %}
      {% if nodes_list | length > 0 %}
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

      {% else %}

      select 
        cast(null as {{ dbt_utils.type_string() }}) as unique_id, 
        cast(null as {{ dbt_utils.type_string() }}) as name, 
        cast(null as {{ dbt_utils.type_string() }}) as resource_type,
        cast(null as {{ dbt_utils.type_string() }}) as file_path, 
        cast(null as boolean) as is_described, 
        cast(null as {{ dbt_utils.type_string() }}) as exposure_type, 
        cast(null as {{ dbt_utils.type_string() }}) as maturity, 
        cast(null as {{ dbt_utils.type_string() }}) as package_name, 
        cast(null as {{ dbt_utils.type_string() }}) as url
      
      where false

      {% endif %}
    {% endif %}

{% endmacro %}