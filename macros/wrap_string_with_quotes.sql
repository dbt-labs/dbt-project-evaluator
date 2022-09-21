{% macro wrap_string_with_quotes(str) %}
  {% if not str %}
    {{ return('cast(NULL as ' ~ dbt.type_string() ~ ')') }}
  {% else %}
    {{ return("'" ~ str ~ "'") }}
  {% endif %}
{% endmacro %}
