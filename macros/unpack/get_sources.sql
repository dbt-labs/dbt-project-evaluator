{% macro get_sources() %}

    {% if execute %}
    {% set nodes_list = graph.sources.values() %}
    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id
            , '{{ node.name }}' as node_name
            , '{{ node.alias }}' as alias
            , '{{ node.resource_type }}' as resource_type
            , '{{ node.source_name }}' as source_name
            , '{{ is_not_empty_string(node.source_description) }}'::boolean as is_source_described
            , '{{ is_not_empty_string(node.description) }}'::boolean as is_described
            , '{{ node.config.enabled }}'::boolean as is_enabled
            , '{{ node.loaded_at_field}}' as loaded_at_field
            , '{{ node.database }}' as database
            , '{{ node.schema }}' as schema
            , '{{ node.package_name }}' as package_name
            , '{{ node.loader }}' as loader
            , '{{ node.identifier }}' as identifier

    {% endfor %}
    {% endif %}
    

{% endmacro %}