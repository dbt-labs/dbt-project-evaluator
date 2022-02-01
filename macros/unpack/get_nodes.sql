{% macro get_nodes() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() %}
    {% set list_nodes = [] %}

    {% for node in nodes_list %}

        {% do list_nodes.append(
          {
            "unique_id": node.unique_id, 
            "node_name": node.node_name or none,
            "resource_type": node.resource_type or none,
            "is_enabled": node.config.enabled or none,
            "materialized": node.config.materialized or none,
            "on_schema_change": node.config.on_schema_change or none,
            "database": node.database or none,
            "schema": node.schema or none,
            "package_name": node.package_name or none,
            "alias": node.alias or none,
          }
        ) %}

    {% endfor %}

    {% set nodes_in_json = tojson(list_nodes) %}
    {{ select_from_json_string(nodes_in_json,[
      "unique_id",
      "node_name",
      "resource_type",
      "is_enabled",
      "materialized",
      "on_schema_change",
      "database",
      "schema",
      "package_name",
      "alias",
      ]) }}

    {% endif %}
  
{% endmacro %}