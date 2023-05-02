{% macro filter_exceptions(model_ref) -%}
    {{ return(adapter.dispatch('filter_exceptions', 'dbt_project_evaluator')(model_ref)) }}
{%- endmacro %}

{% macro default__filter_exceptions(model_ref) %}

    {% set query_filters %}
    select
        column_name,
        id_to_exclude
    from {{ ref('dbt_project_evaluator_exceptions') }}
    where fct_name = '{{ model_ref.name }}'
    {% endset %}

    {% if execute %}
        {# Start with a where that is always true #}
        where 1 = 1

        {% set is_default_seed = 'dbt_project_evaluator' in graph.nodes.values() | 
            selectattr('resource_type', 'equalto', 'seed') | 
            selectattr('name', 'equalto', 'dbt_project_evaluator_exceptions') | 
            map(attribute = 'package_name') | list %}

        {% if not is_default_seed %}
        
            {% if flags.WHICH not in ['compile'] %}
                {% for row_filter in run_query(query_filters) %}
                    and {{ row_filter[0] }} not like '{{ row_filter[1] }}'
                {% endfor %}
            {% endif %}
        
        {% endif %}

        {% if not var('include_package_models') %}
            and package_name = '{{ project_name }}'
        {% endif %}

    {% endif %}

{% endmacro %}