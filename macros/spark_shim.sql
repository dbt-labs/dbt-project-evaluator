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

{% macro spark__array_construct(inputs, data_type) -%}
    array( {{ inputs|join(' , ') }} )
{%- endmacro %} 

{% macro spark__array_concat(array_1, array_2) -%}
    concat({{ array_1 }}, {{ array_2 }})
{%- endmacro %}

{% macro spark__array_append(array, new_element) -%}
    {{ dbt_utils.array_concat(array, dbt_utils.array_construct([new_element])) }}
{%- endmacro %}