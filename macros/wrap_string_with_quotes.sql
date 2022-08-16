{% macro wrap_string_with_quotes(str) %}
  {% if not str %}
    {{ return('NULL') }}
  {% else %}
    {{ return("'" ~ str ~ "'") }}
  {% endif %}
{% endmacro %}
