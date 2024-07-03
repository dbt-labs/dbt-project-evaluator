{%- macro type_string() -%}
    {{ return(adapter.dispatch('type_string', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__type_string() -%}
    {{ return(dbt.type_string()) }}
{%- endmacro -%}

{%- macro redshift__type_string() -%}
    varchar(600)
{%- endmacro -%}
