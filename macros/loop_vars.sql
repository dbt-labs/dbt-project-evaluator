{% macro loop_vars(vars) %}
    {{ return(adapter.dispatch('loop_vars', 'dbt_project_evaluator')(vars)) }}
{% endmacro %}

{% macro default__loop_vars(vars) %}
{%- set sql_query = [] -%}
{%- for var_name in vars -%}
    {%- if var(var_name,[]) is not string -%}
        {%- for var_value in var(var_name,[]) -%}
            {% set sql_command %}
            select '{{ var_name }}' as var_name, '{{ var_value }}' as var_value
            {% endset %}
            {%- do sql_query.append(sql_command) -%}
        {%- endfor -%}
    {%- else -%}
        {% set sql_command %}
        select '{{ var_name }}' as var_name, '{{ var(var_name,[]) }}' as var_value
        {% endset %}
        {%- do sql_query.append(sql_command) -%}
    {%- endif -%}
{%- endfor -%}
{%- if sql_query -%}
{{ sql_query | join('union all') }}
{%- else -%}
select '' as var_name, '' as var_value
limit 0
{%- endif -%}
{% endmacro %}