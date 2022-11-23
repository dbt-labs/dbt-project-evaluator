{% macro directory_pattern() %}
  {%- if env_var("HOME", "not_set") != "not_set" -%}
     {% if "\\\\" not in env_var("HOME", "not_set") %}
       {{ return("/") }}
     {% else %}
       {{ return("\\\\") }}
     {% endif %}
  {%- else -%}
      {{ return("\\\\") }}
  {%- endif -%}
{% endmacro %}
 
{% macro regexp_directory_pattern() %}
  {%- if env_var("HOME", "not_set") != "not_set" -%}
     {% if "\\\\" not in env_var("HOME", "not_set") %}
       {{ return("/") }}
     {% else %}
       {{ return("\\\\\\\\") }}
     {% endif %}
  {%- else -%}
      {{ return("\\\\\\\\") }}
  {%- endif -%}
{% endmacro %}
