{% macro filter_exceptions(model_ref) -%}
    {{ return(adapter.dispatch('filter_exceptions', 'dbt_project_evaluator')(model_ref)) }}
{%- endmacro %}

{% macro default__filter_exceptions(model_ref) %}

    {% if execute %}
    {% set is_custom_seed = graph.nodes.values() | 
            selectattr('resource_type', 'equalto', 'seed') | 
            selectattr('name', 'equalto', 'dbt_project_evaluator_exceptions') | 
            selectattr('package_name', 'equalto', 'dbt_project_evaluator') is none %}

    {% if is_custom_seed %}

        {% set query_filters %}
        select
            column_name,
            id_to_exclude
        from {{ ref('dbt_project_evaluator_exceptions') }}
        where fct_name = '{{ model_ref.name }}'
        {% endset %}
    
        {% if execute and flags.WHICH not in ['compile'] %}
            where 1 = 1
            {% for row_filter in run_query(query_filters) %}
                and {{ row_filter[0] }} not like '{{ row_filter[1] }}'
            {% endfor %}
        {% endif %}
    
    {% endif %}

    {% endif %}

{% endmacro %}