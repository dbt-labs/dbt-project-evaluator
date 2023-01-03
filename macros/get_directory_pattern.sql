-- these macros will read a user’s home environment and detect whether a computer’s operating system is Windows based or Mac/Linux, and display the right directory pattern.
{% macro get_directory_pattern() %}
  {%- set env_var_home_exists = env_var("HOME", "not_set") != "not_set" -%}
  {%- set on_mac_or_linux = env_var_home_exists and "\\\\" not in env_var("HOME") -%}
  {%- if on_mac_or_linux -%}
    {{ return("/") }}
  {% else %}
    {{ return("\\\\") }}
  {% endif %}
{% endmacro %}
 
{% macro get_regexp_directory_pattern() %}
  {% set regexp_escaped = get_directory_pattern() | replace("\\\\", "\\\\\\\\") %}
  {% do return(regexp_escaped) %}
{% endmacro %}
 
{% macro get_dbtreplace_directory_pattern() %}
  {%- set env_var_home_exists = env_var("HOME", "not_set") != "not_set" -%}
  {%- set on_mac_or_linux = env_var_home_exists and "\\\\" not in env_var("HOME") -%}
  {%- if on_mac_or_linux -%}
    {{ dbt.replace("file_path", "regexp_replace(file_path,'.*/','')", "''") }}
  {% else %}
    {{ dbt.replace("file_path", "regexp_replace(file_path,'.*\\\\\\\\','')", "''") }}
  {% endif %}
{% endmacro %} 