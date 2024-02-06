{% macro insert_resources_from_graph(relation, resource_type='nodes', relationships=False, columns=False, batch_size=var('insert_batch_size') | int) %}
  {%- set values = get_resource_values(resource_type, relationships, columns) -%}
  {%- set values_length = values | length -%}
  {%- set loop_count = (values_length / batch_size) | round(0, 'ceil') | int -%}
  
    {%- for loop_number in range(loop_count) -%}
        {%- set lower_bound = loop.index0 * batch_size -%}
        {%- set upper_bound = loop.index * batch_size -%}
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