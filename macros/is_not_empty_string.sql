{% macro is_not_empty_string(str) %}

    {% if str %}
    {{ true }}
    {% else %}
    {{ false }}
    {% endif %}

{% endmacro %}