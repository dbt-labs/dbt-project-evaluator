{%- macro clickhouse__type_string() -%}
  {{ 'Nullable(String)' }}
{%- endmacro %}

{%- macro clickhouse__type_int() -%}
  {{ 'Nullable(Int32)' }}
{%- endmacro %}

{%- macro clickhouse__type_float() -%}
  {{ 'Nullable(Float32)' }}
{%- endmacro %}

{%- macro clickhouse__type_boolean() -%}
  {{ 'Nullable(Bool)' }}
{%- endmacro %}

{% macro clickhouse__replace(string_text, pattern, replacement) -%}
    replaceAll(assumeNotNull({{string_text}}), {{pattern}}, {{replacement}})
{%- endmacro %} 

{% macro clickhouse__split_part(string_text, delimiter_text, part_number) -%}
    splitByChar({{delimiter_text}}, assumeNotNull({{string_text}}))[{{part_number}}]
{%- endmacro %} 

{% macro clickhouse__listagg(measure, delimiter_text, order_by_clause, limit_num) -%}

    {% set arr = "array_agg({})".format(measure) %}

    {% set arr = "arraySort({}, {})".format(arr, order_by_clause) if order_by_clause else arr %}

    {% if limit_num -%}
      arrayStringConcat(arraySlice({{ arr }}, 1, {{ limit_num }}), {{ delimiter_text }})
    {% else -%}
      arrayStringConcat({{ arr }}, {{ delimiter_text }})
    {%- endif %}

{%- endmacro %}
