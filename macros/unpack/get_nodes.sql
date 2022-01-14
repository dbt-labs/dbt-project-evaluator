{% macro get_nodes() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() %}
    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id
            , '{{ node.name }}' as node_name
            , '{{ node.resource_type }}' as resource_type
            , '{{ node.config.enabled }}'::boolean as is_enabled
            , '{{ node.config.materialized }}' as materialized
            , '{{ node.config.on_schema_change}}' as on_schema_change
            , '{{ node.database }}' as database
            , '{{ node.schema }}' as schema
            , '{{ node.package_name }}' as package_name
            , '{{ node.alias }}' as alias

    {% endfor %}
    {% endif %}
  
{% endmacro %}