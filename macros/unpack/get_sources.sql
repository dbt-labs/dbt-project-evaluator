{% macro get_sources() %}

    {% if execute %}
    {% set nodes_list = graph.sources.values() %}
    {% set list_nodes = [] %}
    {% for node in nodes_list %}

        {% do list_nodes.append(
          {
            "unique_id": node.unique_id, 
            "node_name": node.node_name or none,
            "alias": node.alias or none,
            "resource_type": node.resource_type or none,
            "source_name": node.source_name or none,
            "is_source_described": true if node.source_description else false,
            "is_described": true if node.description else false,
            "is_enabled": node.is_enabled or none,
            "loaded_at_field": node.loaded_at_field or none,
            "database": node.database or none,
            "schema": node.schema or none,
            "package_name": node.package_name or none,
            "loader": node.loader or none,
            "identifier": node.identifier or none
          }
        ) %}

    {% endfor %}

    {% set nodes_in_json = tojson(list_nodes) %}
    {{ select_from_json_string(nodes_in_json,[
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
      ]) }}

    {% endif %}
    

{% endmacro %}