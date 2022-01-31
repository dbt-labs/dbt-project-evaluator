{% macro get_metrics() %}

    {% if execute %}
    {% set nodes_list = graph.metrics.values() %}
    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id
            , '{{ node.name }}' as node_name
            , '{{ node.resource_type }}' as resource_type
            , {{ safe_quote_string(node.description) }} as description
            , '{{ node.type }}' as metric_type
            , '{{ node.model.identifier }}' as model
            , '{{ node.label }}' as label
            , '{{ node.sql }}' as sql
            , '{{ node.timestamp }}' as timestamp
            , '{{ node.package_name }}' as package_name


    {% endfor %}
    {% endif %}
  
{% endmacro %}