{% macro generate_insert_statements_post_hook(relation, resource_type='nodes', relationships=False, batch_size=100) %}
  {%- set values = get_resource_values(resource_type, relationships) -%}
  {%- set values_length = values | length -%}
  {%- set loop_count = (values_length / batch_size) | round(0, 'ceil') | int -%}
  
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
        {% call statement('insert') -%}
            {{ insert_statement }}
        {%- endcall %}
    {% endfor %}
    
{% endmacro %}