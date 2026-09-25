{% macro quote_identifier(name) %}
    {{ return(adapter.dispatch('quote_identifier', 'dbt_project_evaluator')(name)) }}
{% endmacro %}

{% macro default__quote_identifier(name) %}{{ name }}{% endmacro %}

{% macro fabric__quote_identifier(name) %}[{{ name }}]{% endmacro %}

{% macro sqlserver__quote_identifier(name) %}{{ return(dbt_project_evaluator.fabric__quote_identifier(name)) }}{% endmacro %}
