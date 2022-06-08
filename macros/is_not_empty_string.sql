{% macro is_not_empty_string(str) %}
    {{ return(adapter.dispatch('is_not_empty_string', 'dbt_project_evaluator')(str)) }}
{% endmacro %}

{% macro default__is_not_empty_string(str) %}

    {% if str %}
    {{ true }}
    {% else %}
    {{ false }}
    {% endif %}

{% endmacro %}