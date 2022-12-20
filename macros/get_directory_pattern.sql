-- these macros will read a user’s home environment and detect whether a computer’s operating system is Windows based or Mac/Linux, and display the right directory pattern.
{% macro get_directory_pattern() %}
  {%- set  env_var_home_exists = env_var("HOME", "not_set") != "not_set" -%}
  {%- if env_var_home_exists -%}
     {% if "\\\\" not in env_var("HOME") %}
       {{ return("/") }}
     {% else %}
       {{ return("\\\\") }}
     {% endif %}
  {%- else -%}
      {{ return("\\\\") }}
  {%- endif -%}
{% endmacro %}
 
{% macro get_regexp_directory_pattern() %}
  {% set regexp_escaped = get_directory_pattern() | replace("\\\\", "\\\\\\\\") %}
  {% do return(regexp_escaped) %}
{% endmacro %}