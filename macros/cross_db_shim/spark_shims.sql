{% macro spark__escape_single_quotes(expression) -%}
    {{ expression | replace("'","\\'") }}
{%- endmacro %}

{% macro fabric__escape_single_quotes(expression) -%}
    {{ expression | replace("'","''") }}
{%- endmacro %}