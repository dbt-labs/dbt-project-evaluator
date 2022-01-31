{% macro safe_quote_string(str) %}

    {% set quote = "'" %}
    {{ quote ~ str | replace("'","\\'") ~ quote }}

{% endmacro %}