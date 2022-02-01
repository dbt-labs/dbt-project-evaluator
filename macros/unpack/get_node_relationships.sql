{% macro get_node_relationships() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() %}
    
    with relationships as (
    {%- for node in nodes_list -%}
    {%- set outer_loop = loop -%}

        {%- if node.depends_on.nodes|length == 0 -%}

        select 
            '{{ node.name }}' as node,
            '{{ node.unique_id }}' as node_id,
            '{{ node.resource_type }}' as resource_type,
            NULL as direct_parent_id

        {%- else -%}       

            {%- for parent in node.depends_on.nodes -%}

            select 
                '{{ node.name }}' as node,
                '{{ node.unique_id }}' as node_id,
                '{{ node.resource_type }}' as resource_type,
                '{{ parent }}'  as direct_parent_id
            {% if not loop.last %}union all{% endif %}

            {% endfor -%}
        
        {%- endif %}

        {% if not outer_loop.last %}union all{% endif %}

    {% endfor -%}

    ), 

    final as (
        select 
            {{ dbt_utils.surrogate_key(['node_id', 'direct_parent_id']) }} as unique_id, 
            *
        from relationships
    )

    select * from final
    {% endif %}
  
{% endmacro %}