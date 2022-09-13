{# Moving this macro into this package to release a dbt-core 1.2 friendly release that does not rely on old dbt_utils versions #}
{# These macro will be deprecated when we release a dbt-core 1.3 friendly release of this pacakge, which will include these macros#}

{% macro array_construct(inputs = [], data_type = api.Column.translate_type('integer')) -%}
  {{ return(adapter.dispatch('array_construct', 'dbt_project_evaluator')(inputs, data_type)) }}
{%- endmacro %}

{# all inputs must be the same data type to match postgres functionality #}
{% macro default__array_construct(inputs, data_type) -%}
    {% if inputs|length > 0 %}
    array[ {{ inputs|join(' , ') }} ]
    {% else %}
    array[]::{{data_type}}[]
    {% endif %}
{%- endmacro %}

{% macro snowflake__array_construct(inputs, data_type) -%}
    array_construct( {{ inputs|join(' , ') }} )
{%- endmacro %}

{% macro redshift__array_construct(inputs, data_type) -%}
    array( {{ inputs|join(' , ') }} )
{%- endmacro %}

{% macro bigquery__array_construct(inputs, data_type) -%}
    [ {{ inputs|join(' , ') }} ]
{%- endmacro %}

{% macro spark__array_construct(inputs, data_type) -%}
    array( {{ inputs|join(' , ') }} )
{%- endmacro %} 