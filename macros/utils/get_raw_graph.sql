{% macro get_raw_graph() %}    
    {% if execute %}
        {% set render = {} %}
        {% set render.nodes = graph.nodes %}
        {% set render.sources = graph.sources %}
        select 

            parse_json(replace('{{ graph | tojson }}','\n')) as manifest
      
    {% endif %}

{% endmacro %}