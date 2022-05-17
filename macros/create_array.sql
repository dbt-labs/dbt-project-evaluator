{% macro create_array(inputs) -%}
  {{ return(adapter.dispatch('array')(inputs)) }}
{%- endmacro %}

{% macro default__array(inputs) -%}
    array( {{ inputs }} )
{%- endmacro %}

{% macro snowflake__array(inputs) -%}
    array_construct( {{ inputs }} )
{%- endmacro %}

{% macro bigquery__array(inputs) -%}
    [ {{ inputs }} ]
{%- endmacro %}

{% macro postgres__array(inputs) -%}
    [ {{ inputs }} ]
{%- endmacro %}