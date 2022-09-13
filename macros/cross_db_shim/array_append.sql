{# Moving this macro into this package to release a dbt-core 1.2 friendly release that does not rely on old dbt_utils versions #}
{# These macro will be deprecated when we release a dbt-core 1.3 friendly release of this pacakge, which will include these macros#}


{% macro array_append(array, new_element) -%}
  {{ return(adapter.dispatch('array_append', 'dbt_project_evaluator')(array, new_element)) }}
{%- endmacro %}

{% macro default__array_append(array, new_element) -%}
    array_append({{ array }}, {{ new_element }})
{%- endmacro %}

{% macro bigquery__array_append(array, new_element) -%}
    {{ array_concat(array, array_construct([new_element])) }}
{%- endmacro %}

{% macro redshift__array_append(array, new_element) -%}
    {{ array_concat(array, array_construct([new_element])) }}
{%- endmacro %}

{% macro spark__array_append(array, new_element) -%}
    {{ array_concat(array, array_construct([new_element])) }}
{%- endmacro %}