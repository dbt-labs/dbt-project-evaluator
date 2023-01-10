{% macro filter_exceptions(model_ref) -%}
  {{ return(adapter.dispatch('filter_exceptions', 'dbt_project_evaluator')(model_ref)) }}
{%- endmacro %}

{% macro default__filter_exceptions(model_ref) %}

{% set query_filters %}
select
    column_name,
    id_to_exclude
from {{ ref('dbt_project_evaluator_exceptions') }}
where '{{ model_ref.name }}' like fct_name
{% endset %}

{% set all_columns = adapter.get_columns_in_relation(model_ref) %}

{% if execute and flags.WHICH not in ['compile'] %}
    where 1 = 1
    {% for row_filter in run_query(query_filters) %}
        {% if '%' in row_filter[0] %}
            {% set column_pattern = row_filter[0] | replace('%', '.*') %}
            {% for column in all_columns if modules.re.match(column_pattern, column.name) %}
                and {{ column.name }} not like '{{ row_filter[1] }}'
            {% endfor %}
        {% else %}
            and {{ row_filter[0] }} not like '{{ row_filter[1] }}'
        {% endif %}
    {% endfor %}
{% endif %}

{% endmacro %}
