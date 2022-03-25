{% macro get_metrics() %}

    {% if execute %}
    {% set nodes_list = graph.metrics.values() %}
    {% set values = [] %}

    {% for node in nodes_list %}

          {% set values_line %}
            (
            '{{ node.unique_id }}', 
            '{{ node.name }}', 
            '{{ node.resource_type }}', 
            '{{ node.path }}',
            {{ is_not_empty_string(node.description) }}, 
            '{{ node.type }}', 
            '{{ node.model.identifier }}', 
            '{{ node.label }}', 
            '{{ node.sql }}', 
            '{{ node.timestamp }}', 
            '{{ node.package_name }}'
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
              'is_described', 
              'metric_type', 
              'model', 
              'label', 
              'sql', 
              'timestamp', 
              'package_name'
            ]
         )
    ) }}

{% endmacro %}