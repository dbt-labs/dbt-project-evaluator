{%- macro select_from_values(values, columns) %}

    {%- set column_names = [] -%}

    {%- set null_values  = [] -%}

    {%- set type_string = dbt_utils.type_string() | trim -%}

    {%- for column in columns %}

        {%- if column is string -%}
            {%- set column_name = column -%}
            {%- set column_type = type_string -%}
        {%- else -%}
            {%- set column_name, column_type = column -%}
        {%- endif -%}
        {% do column_names.append(column_name) %}
        {% do null_values.append("cast(null as " ~ column_type | trim ~" )")  %}
        
    {%- endfor -%}

    {%- if values %}
        {{ return(adapter.dispatch('select_from_values', 'dbt_project_evaluator')(values, column_names)) }}
    {%- else -%} -- if values is an empty list, return an empty table
        -- Creates a one-record table with NULL for every column. Then, filters out the NULL records so the final table is empty.
        {{ return(adapter.dispatch('select_from_values', 'dbt_project_evaluator')([null_values], column_names) ~ 'where ' ~ column_names[0] ~ ' is not null') }}

    {% endif -%}

{% endmacro -%}


{%- macro default__select_from_values(values,column_names) %}

    {#-
    The default implementation leverages the following syntax

    select * from ( values ('val1a','val2a','val3a'), ('val1b','val2b','val3b') ) as t (col_name1, col_name2, col_name3)
    -#}

    {%- set column_names_string = column_names | join(", \n") -%}

    {%- set values_list_of_strings = [] -%}

    {%- for indiv_values in values -%}
      {%- do values_list_of_strings.append( indiv_values | join(", \n")) -%}
    {%- endfor -%}

    {%- set values_string = '(' ~ values_list_of_strings | join("), \n\n(") ~ ')' -%}

        with cte as (

            select * from ( 
                    values {{ values_string }} 
                ) as t ({{ column_names_string }})

        )

        select * from cte

{% endmacro -%}



{%- macro bigquery__select_from_values(values,column_names) -%}

    {# 
    The bigquery implementation leverages the following syntax

    select * from unnest( [ struct('val1a' as col_name1, 'val2a' as col_name2, 'val3a' as col_name3), ('val1b','val2b','val3b') ] )
    #}

    {%- if execute and values -%}

        {%- set first_row = values[0] -%}
        {%- set following_rows_list_of_strings = [] -%}

        {%- for values_row in values[1:] -%}
            {%- do following_rows_list_of_strings.append( values_row | join(", \n")) -%}
        {%- endfor -%}

        {%- set following_rows = '(' ~ following_rows_list_of_strings | join("), \n\n(") ~ ')' -%}

        {%- set struct_header = [] %}
        {%- for column in column_names -%}

            {%- set name %}
                {{ first_row[loop.index0] }} as {{ column }}
            {% endset -%}
            {%- do struct_header.append(name) -%}
        
        {%- endfor -%}

        {%- set struct_header_string = struct_header | join(', ') -%}

        select 
            * 
        from 
            unnest([    
                struct( {{ struct_header_string }} )
                {% if following_rows != '()' %}
                , {{ following_rows }}
                {% endif %}
        ])

    {%- endif -%}

{%- endmacro -%}


{%- macro redshift__select_from_values(values,column_names) -%}

    {# 
    Redshift does not support the values keyword
    The Redshift implementation falls back on using the following syntax, which had poor performance on other DWs
    
    select 
        'val1a' as col_name1,
        'val2a' as col_name2,
        'val3a' as col_name3
    union all
    select
        'val1b' as col_name1,
        'val2b' as col_name2,
        'val3b' as col_name3
    #}

    {% set all_select_to_union = [] %}

    {%- for value in values %}

        {%- set all_statements_in_union = [] %}
        {%- set individual_values = value %}

        {%- for column_value in individual_values %}

            {%- set column_value_and_name %}
                {{ column_value }} as {{ column_names[loop.index0] }}
            {%- endset %}
            {%- do all_statements_in_union.append(column_value_and_name) %}    
   
        {%- endfor %}
        {%- do all_select_to_union.append(all_statements_in_union | join(', ')) %}
      
    {%- endfor %}

select 
{{ all_select_to_union | join(' 
    union all 
    select 
    ') 
}}

{% endmacro -%}