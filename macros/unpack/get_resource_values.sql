{% macro get_resource_values(resource=None, relationships=None, columns=None) %}
  {% if relationships %}
    {{ return(adapter.dispatch('get_relationship_values', 'dbt_project_evaluator')(node_type=resource)) }}
  {% elif columns %}
    {{ return(adapter.dispatch('get_column_values', 'dbt_project_evaluator')(node_type=resource)) }}
  {% elif resource == 'exposures' %}
    {{ return(adapter.dispatch('get_exposure_values', 'dbt_project_evaluator')()) }}
  {% elif resource == 'sources' %}
    {{ return(adapter.dispatch('get_source_values', 'dbt_project_evaluator')()) }}
  {% elif resource == 'metrics' %}
    {{ return(adapter.dispatch('get_metric_values', 'dbt_project_evaluator')()) }}
  {% elif resource == 'nodes' %}
    {{ return(adapter.dispatch('get_node_values', 'dbt_project_evaluator')()) }}
  {% endif %}
{% endmacro %}