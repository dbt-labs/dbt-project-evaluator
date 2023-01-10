{% macro filter_exceptions(model_ref, model_query) -%}
  {{ return(adapter.dispatch('filter_exceptions', 'dbt_project_evaluator')(model_ref, model_query)) }}
{%- endmacro %}

{% macro default__filter_exceptions(model_ref, model_query) %}

{% set query_filters %}
select
    column_name,
    id_to_exclude
from {{ ref('dbt_project_evaluator_exceptions') }}
where '{{ model_ref.name }}' like fct_name
{% endset %}

{% if execute and flags.WHICH not in ['compile'] %}

    {% set all_columns = get_columns_in_query(model_query) %}

    where 1 = 1
    {% for row_filter in run_query(query_filters) %}
        {% if '%' in row_filter[0] %}
            {% set column_pattern = row_filter[0] | replace('%', '.*') %}
            {% for column_name in all_columns if modules.re.match(column_pattern, column_name) %}
                and coalesce(cast({{ column_name }} as {{ dbt.type_string() }}),'') not like '{{ row_filter[1] }}'
            {% endfor %}
        {% else %}
            and coalesce(cast({{ row_filter[0] }} as {{ dbt.type_string() }}),'') not like '{{ row_filter[1] }}'
        {% endif %}
    {% endfor %}
{% endif %}

{% endmacro %}
