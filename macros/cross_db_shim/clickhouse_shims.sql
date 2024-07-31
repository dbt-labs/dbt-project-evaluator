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

{% macro clickhouse__load_csv_rows(model, agate_table) %}
  {% set cols_sql = get_seed_column_quoted_csv(model, agate_table.column_names) %}
  {% set data_sql = adapter.get_csv_data(agate_table) %}

  {% if data_sql %}
    {% set sql -%}
      insert into {{ this.render() }} ({{ cols_sql }})
      {{ adapter.get_model_query_settings(model) }}
      format CSV
      {{ data_sql }}
    {%- endset %}

    {% do adapter.add_query(sql, bindings=agate_table, abridge_sql_log=True) %}
  {% endif %}
{% endmacro %}
