{% macro generate_insert_statements(relation, values, batch_size=100) %}
  {%- set values_length = values | length -%}
  {%- set loop_count = (values_length / batch_size) | round(0, 'ceil') | int -%}
  
  {% set insert_statements = [] -%}
    {%- for loop_number in range(loop_count) -%}
        {%- set lower_bound = loop.index0 * batch_size -%}
        {%- set upper_bound = loop.index * batch_size -%}
        {# TODO handle end of range #}
        {%- set values_subset = values[lower_bound : upper_bound] %}
        {%- set values_list_of_strings = [] -%}
        {%- for indiv_values in values_subset %}
            {%- do values_list_of_strings.append( indiv_values | join(", \n")) -%}
        {%- endfor -%}
        {%- set values_string = '(' ~ values_list_of_strings | join("), \n\n(") ~ ')' %}
        {%- set insert_statement = "insert into " ~ relation ~ " values \n" ~  values_string ~ ";"%}
        {%- do insert_statements.append(insert_statement) -%}
    {% endfor %}
    {{ return(insert_statements) }}
{% endmacro %}