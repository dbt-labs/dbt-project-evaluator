{%- macro type_large_string() -%}
    {{ return(adapter.dispatch('type_large_string', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__type_large_string() -%}
    {{ return(dbt.type_string()) }}
{%- endmacro -%}

{%- macro redshift__type_large_string() -%}
    varchar(5000)
{%- endmacro -%}