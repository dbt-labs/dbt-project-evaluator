{% macro create_array(inputs) -%}
  {{ return(adapter.dispatch('array')(inputs)) }}
{%- endmacro %}

{% macro default__array(inputs) -%}
    [ {{ inputs }} ]
{%- endmacro %}

{% macro snowflake__array(inputs) -%}
    array_construct( {{ inputs }} )
{%- endmacro %}

{% macro redshift__array(inputs) -%}
    array( {{ inputs }} )
{%- endmacro %}