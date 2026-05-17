{% macro fabric__escape_single_quotes(expression) -%}
    {{ expression | replace("'","''") }}
{%- endmacro %}

{% macro quote_identifier(name) %}
    {{ return(adapter.dispatch('quote_identifier', 'dbt_project_evaluator')(name)) }}
{% endmacro %}

{% macro default__quote_identifier(name) %}{{ name }}{% endmacro %}

{% macro fabric__quote_identifier(name) %}[{{ name }}]{% endmacro %}

{# Convert a Python boolean to a SQL boolean literal appropriate for the target adapter #}
{% macro bool_literal(value) %}
    {{ return(adapter.dispatch('bool_literal', 'dbt_project_evaluator')(value)) }}
{% endmacro %}

{% macro default__bool_literal(value) %}{{ value | trim }}{% endmacro %}

{% macro fabric__bool_literal(value) %}{% if value %}1{% else %}0{% endif %}{% endmacro %}
