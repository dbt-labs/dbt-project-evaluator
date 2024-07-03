{%- macro type_string() -%}
    {{ return(adapter.dispatch('type_string', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__type_string() -%}
    {{ return(api.Column.string_type(600)) }}
{%- endmacro -%}

{%- macro bigquery__type_string() -%}
    {{ return("STRING") }}
{%- endmacro -%}
