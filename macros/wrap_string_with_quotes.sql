{% macro wrap_string_with_quotes(str) %}
  {% if str is none %}
    {{ return('cast(NULL as ' ~ dbt_project_evaluator.type_string_dpe() ~ ')') }}
  {% else %}
    {{ dbt.string_literal(str) }}
  {% endif %}
{% endmacro %}