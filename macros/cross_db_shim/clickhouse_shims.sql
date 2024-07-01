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
    {% if order_by_clause and ' by ' in order_by_clause -%}
      {% set order_by_field = order_by_clause.split(' by ')[1] %}
      {% set arr = "arrayMap(x -> x.1, arrayReverseSort(x -> x.2, arrayZip(array_agg({}), array_agg({}))))".format(arr, order_by_field) %}
    {% else -%}
      {% set arr = "array_agg({})".format(measure) %}
    {%- endif %}

    {% if limit_num -%}
      arrayStringConcat(arraySlice({{ arr }}, 1, {{ limit_num }}), {{delimiter_text}})
    {% else -%}
      arrayStringConcat({{ arr }}, {{delimiter_text}})
    {%- endif %}
{%- endmacro %}
