{% macro wrap_string_with_quotes() %}
    {{ return(adapter.dispatch('wrap_string_with_quotes', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__wrap_string_with_quotes(str) %}
  {% if not str %}
    {{ return('cast(NULL as ' ~ dbt.type_string() ~ ')') }}
  {% else %}
    {{ return("'" ~ str ~ "'") }}
  {% endif %}
{% endmacro %}

{% macro bigquery__wrap_string_with_quotes(str) %}
  {% if not str %}
    {{ return('cast(NULL as ' ~ dbt.type_string() ~ ')') }}
  {% else %}
    {{ return("'''" ~ str ~ "'''") }}
  {% endif %}
{% endmacro %}
