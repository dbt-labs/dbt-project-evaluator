{% macro select_from_values(values,column_names) %}
    {{ return(adapter.dispatch('select_from_values')(values, column_names)) }}
{% endmacro %}


{% macro default__select_from_values(values,column_names) %}

    {# 
    The default implementation leverages the following syntax

    select * from ( values ('val1a','val2a','val3a'), ('val1b','val2b','val3b') ) as t (col_name1, col_name2, col_name3)
    #}

    {% set column_names_string = column_names | join(', ') %}
    {% set values_string =  values | join(", ") %}

        with cte as (

            select * from ( 
                    values {{ values_string }} 
                ) as t ({{ column_names_string }})

        )

        select * from cte

{% endmacro %}



{% macro bigquery__select_from_values(values,column_names) %}

    {# 
    The bigquery implementation leverages the following syntax

    select * from unnest( [ struct('val1a' as col_name1, 'val2a' as col_name2, 'val3a' as col_name3), ('val1b','val2b','val3b') ] )
    #}

    {% set first_value_in_list = values[0].replace('(','').replace(')','').split(',') %}
    {% set following_values_string =  values[1:] | join(", ") %}

    {% set struct_header = [] %}
    {% for column in column_names %}

        {% set name %}
            {{ first_value_in_list[loop.index0] }} as {{ column }}
        {% endset %}
        {% do struct_header.append(name) %}
      
    {% endfor %}

    {% set struct_header_string = struct_header | join(', ') %}

    select 
        * 
    from 
        unnest([    
            struct( {{ struct_header_string }} ),
            {{ following_values_string }}
        ])

{% endmacro %}


{% macro redshift__select_from_values(values,column_names) %}

    {# 
    Redshift doe not support the values keyword
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
        {%- set individual_values = value.replace('(','').replace(')','').split(',') %}

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

{% endmacro %}