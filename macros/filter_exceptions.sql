{% macro filter_exceptions() -%}
    {{ return(adapter.dispatch('filter_exceptions', 'dbt_project_evaluator')()) }}
{%- endmacro %}

{% macro default__filter_exceptions() %}

    {% set query_filters %}
    select
        column_name,
        id_to_exclude
    from {{ ref('dbt_project_evaluator_exceptions') }}
    where fct_name = '{{ model.name }}'
    {% endset %}

    {% if execute %}
    {% set is_default_seed = 'dbt_project_evaluator' in graph.nodes.values() | 
        selectattr('resource_type', 'equalto', 'seed') | 
        selectattr('name', 'equalto', 'dbt_project_evaluator_exceptions') | 
        map(attribute = 'package_name') | list %}

    {% if not is_default_seed %}
    
        {% if flags.WHICH not in ['compile'] %}
            where 1 = 1
            {% for row_filter in run_query(query_filters) %}
                and {{ row_filter[0] }} not like '{{ row_filter[1] }}'
            {% endfor %}
        {% endif %}
    
    {% endif %}

    {% endif %}

{% endmacro %}