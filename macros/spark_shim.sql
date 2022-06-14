{% macro spark__listagg(measure, delimiter_text, order_by_clause, limit_num) -%}

    {# 
        This is not the full support for listagg on databricks but it allows tests to pass/fail for this package
    #}

    {% if limit_num -%}
        {%- do exceptions.raise_compiler_error("listagg on databricks doesn't support limit_num") -%}
    {%- endif %}
    array_join(
        sort_array(
            array_agg(
                {{ measure }}
                )
        )
        ,
        {{ delimiter_text }}
    )

{%- endmacro %}