{%- macro type_string_dpe() -%}
    {{ return(adapter.dispatch('type_string_dpe', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__type_string_dpe() -%}
    {{ return(dbt.type_string()) }}
{%- endmacro -%}

{%- macro redshift__type_string_dpe() -%}
    {{ return(api.Column.string_type(600)) }}
{%- endmacro -%}
