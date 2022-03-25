{% macro listagg(measure, delimiter_text, order_by_clause) %}
  {{ return(adapter.dispatch('listagg')(measure, delimiter_text, order_by_clause)) }}
{% endmacro %}


{% macro default__listagg(measure, delimiter_text, order_by_clause) %}

    listagg(
        {{ measure }},
        '{{ delimiter_text }}'
        {% if order_by_clause %}
        ) within group {{ order_by_clause }}
        {% else %}
        )
        {% endif %}

{% endmacro %}


{% macro postgres__listagg(measure, delimiter_text, order_by_clause) %}

    string_agg(
        {{ measure }},
        '{{ delimiter_text }}',
        {{ order_by_clause }}
        )

{% endmacro %}

{% macro bigquery__listagg(measure, delimiter_text, order_by_clause) %}

    string_agg(
        {{ measure }},
        '{{ delimiter_text }}',
        {{ order_by_clause }}
        )

{% endmacro %}