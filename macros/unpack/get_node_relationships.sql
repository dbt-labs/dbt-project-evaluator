{% macro get_node_relationships() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() %}
    {% set list_nodes = [] %}
    
    {%- for node in graph.nodes.values() -%}
  
        {%- if node.depends_on.nodes|length == 0 -%}

        {% do list_nodes.append({"node": node.name, "node_id": node.unique_id, "resource_type": node.resource_type, "direct_parent_id": none}) %}

        {%- else -%}       

            {%- for parent in node.depends_on.nodes -%}
            {% do list_nodes.append({"node": node.name, "node_id": node.unique_id, "resource_type": node.resource_type, "direct_parent_id": parent}) %}
            {% endfor -%}
        
        {%- endif %}

    {% endfor -%}


    {# build a real JSON object, query it and create a select statement with all columns #}
    {% set nodes_in_json = tojson(list_nodes) %}
    with relationships as (
        {{ select_from_json_string(nodes_in_json,['node','node_id','resource_type','direct_parent_id']) }}
    )

    , final as (
        select 
            {{ dbt_utils.surrogate_key(['node_id', 'direct_parent_id']) }} as unique_id, 
            *
        from relationships
    )

    select * from final

    {% endif %}

{% endmacro %}