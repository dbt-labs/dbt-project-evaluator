{# Moving this macro into this package to release a dbt-core 1.2 friendly release that does not rely on old dbt_utils versions #}
{# These macro will be deprecated when we release a dbt-core 1.3 friendly release of this pacakge, which will include these macros#}

{% macro array_concat(array_1, array_2) -%}\
  {{ return(adapter.dispatch('array_concat', 'dbt_project_evaluator')(array_1, array_2)) }}
{%- endmacro %}

{% macro default__array_concat(array_1, array_2) -%}
    array_cat({{ array_1 }}, {{ array_2 }})
{%- endmacro %}

{% macro bigquery__array_concat(array_1, array_2) -%}
    array_concat({{ array_1 }}, {{ array_2 }})
{%- endmacro %}

{% macro redshift__array_concat(array_1, array_2) -%}
    array_concat({{ array_1 }}, {{ array_2 }})
{%- endmacro %}

{% macro spark__array_concat(array_1, array_2) -%}
    concat({{ array_1 }}, {{ array_2 }})
{%- endmacro %}