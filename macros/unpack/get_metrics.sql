{% macro get_metrics() %}
    {{ return(adapter.dispatch('get_metrics', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__get_metrics() %}

    {% if execute %}
    {% set nodes_list = graph.metrics.values() %}
      {% if nodes_list | length > 0 %}
        {% set values = [] %}

        {% for node in nodes_list %}

              {% set values_line %}

                '{{ node.unique_id }}',
                '{{ node.name }}',
                '{{ node.resource_type }}',
                '{{ node.original_file_path }}',
                cast('{{ dbt_project_evaluator.is_not_empty_string(node.description) | trim }}' as boolean),
                '{{ node.type }}',
                '{{ node.model.identifier }}',
                '{{ node.label }}',
                '{{ node.sql }}',
                '{{ node.timestamp }}',
                '{{ node.package_name }}',
                '{{ node.dimensions|join(' - ') }}',
                {% if node.filters|length %}
                  {% for filt in node.filters %}
                    '{{ filt.field }}'||'{{ filt.operator }}'||'''{{ filt.value }}'''
                    {% if not loop.last %}|| ' - '{% endif %}
                  {% endfor %}
                {% else %}
                    ''
                {% endif %}
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
                  'metric_type', 
                  'model',
                  'label', 
                  'sql', 
                  'timestamp', 
                  'package_name',
                  'dimensions',
                  'filters'
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
          cast(null as {{ dbt_utils.type_string() }}) as metric_type, 
          cast(null as {{ dbt_utils.type_string() }}) as model,
          cast(null as {{ dbt_utils.type_string() }}) as label, 
          cast(null as {{ dbt_utils.type_string() }}) as sql, 
          cast(null as {{ dbt_utils.type_string() }}) as timestamp, 
          cast(null as {{ dbt_utils.type_string() }}) as package_name,
          cast(null as {{ dbt_utils.type_string() }}) as dimensions,
          cast(null as {{ dbt_utils.type_string() }}) as filters

        where false 
      {% endif %}
    
    {% endif %}

{% endmacro %}
