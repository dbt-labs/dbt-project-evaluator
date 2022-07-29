{% macro filter_exceptions(model_ref) %}

{% set query_filters %}
select 
    column_name, 
    id_to_exclude 
from {{ ref('dbt_project_evaluator_exceptions') }}
where fct_name = '{{ model_ref.name }}'
{% endset %}

{% if execute %}
    where 1 = 1
    {% for row_filter in run_query(query_filters) %}
        and {{ row_filter[0] }} not like '{{ row_filter[1] }}'
    {% endfor %}
{% endif %}
  
{% endmacro %}