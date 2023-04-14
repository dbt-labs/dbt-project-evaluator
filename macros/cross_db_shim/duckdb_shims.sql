
{% macro duckdb__split_part(string_text, delimiter_text, part_number) -%}
    str_split({{string_text}}, {{delimiter_text}})[{{part_number}}]
{%- endmacro %} 

{% macro duckdb__listagg(measure, delimiter_text, order_by_clause, limit_num) -%}

    {# 
        This is not the full support for listagg on DuckDB but it allows tests to pass/fail for this package
        - order_by_clause does not work, so we need to sort the CTE before calling listagg
        - support for limit_num was not added
    #}

    {% if limit_num -%}
        {%- do exceptions.raise_compiler_error("listagg on DuckDB doesn't support limit_num") -%}
    {%- endif %}

    string_agg(
        {{ measure }}
        , {{ delimiter_text }}
        {{ order_by_clause }}
        )

{%- endmacro %}