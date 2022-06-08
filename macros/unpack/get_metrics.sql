{% macro get_metrics() %}
    {{ return(adapter.dispatch('get_metrics', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__get_metrics() %}

    {% if execute %}
    {% set nodes_list = graph.metrics.values() %}
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
                {% if not loop.last %}|| ' - '{% else %}{% endif %}
              {% endfor %}
            {% else %}
                ''
            {% endif %}
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

{% endmacro %}
