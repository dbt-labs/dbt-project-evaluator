{% macro graph_testing() %}

    {% set all_models = graph.nodes.values() | selectattr("resource_type", "equalto", "model") | list %}

    {{ log(all_models, info=True) }}
    
{% endmacro %}