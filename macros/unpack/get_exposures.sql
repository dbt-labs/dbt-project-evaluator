{% macro get_exposures() %}

    {% if execute %}
    {% set nodes_list = graph.exposures.values() %}
    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id
            , '{{ node.name }}' as node_name
            , '{{ node.resource_type }}' as resource_type
            , '{{ node.description }}' as description
            , '{{ node.type }}' as exposure_type
            , '{{ node.maturity}}' as maturity
            , '{{ node.package_name }}' as package_name
            , '{{ node.url }}' as url

    {% endfor %}
    {% endif %}
    

{% endmacro %}