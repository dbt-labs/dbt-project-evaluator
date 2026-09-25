{% macro spark__escape_single_quotes(expression) -%}
    {{ expression | replace("'","\\'") }}
{%- endmacro %}

{% macro fabric__escape_single_quotes(expression) -%}
    {{ expression | replace("'","''") }}
{%- endmacro %}

{% macro sqlserver__escape_single_quotes(expression) -%}
    {{ return(dbt_project_evaluator.fabric__escape_single_quotes(expression)) }}
{%- endmacro %}
