{% macro get_metrics() %}

    {% if execute %}
    {% set nodes_list = graph.metrics.values() | selectattr('package_name', 'eq', project_name) | list %}
    {% set values = [] %}

    {% for node in nodes_list %}

          {% set values_line %}
            (
            '{{ node.unique_id }}', 
            '{{ node.name }}', 
            '{{ node.resource_type }}', 
            cast('{{ is_not_empty_string(node.description) | trim }}' as boolean), 
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
              'node_name', 
              'resource_type', 
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