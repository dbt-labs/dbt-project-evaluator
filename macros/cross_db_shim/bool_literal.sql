{# Convert a Python boolean to a SQL boolean literal appropriate for the target adapter #}
{% macro bool_literal(value) %}
    {{ return(adapter.dispatch('bool_literal', 'dbt_project_evaluator')(value)) }}
{% endmacro %}

{% macro default__bool_literal(value) %}{{ value | trim }}{% endmacro %}

{% macro fabric__bool_literal(value) %}{% if value %}1{% else %}0{% endif %}{% endmacro %}
