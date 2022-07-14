{% macro wrap_string_with_quotes(str) %}
  {{ return("'" ~ str ~ "'") }}
{% endmacro %}
