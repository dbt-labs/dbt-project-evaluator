{%- macro get_column_values(node_type) -%}
    {{ return(adapter.dispatch('get_column_values', 'dbt_project_evaluator')(node_type)) }}
{%- endmacro -%}

{%- macro default__get_column_values(node_type) -%}

    {%- if execute -%}
        {%- if node_type == 'nodes' %}
            {% set nodes_list = graph.nodes.values() %}   
        {%- elif node_type == 'sources' -%}
            {% set nodes_list = graph.sources.values() %}
        {%- else -%}
            {{ exceptions.raise_compiler_error("node_type needs to be either nodes or sources, got " ~ node_type) }}
        {% endif -%}

        {%- set values = [] -%}

        {%- for node in nodes_list -%}
            {%- for column in node.columns.values() -%}

                {%- set values_line  = 
                    [
                        wrap_string_with_quotes(node.unique_id),
                        wrap_string_with_quotes(dbt.escape_single_quotes(column.name)),
                        wrap_string_with_quotes(dbt.escape_single_quotes(column.description)),
                        wrap_string_with_quotes(dbt.escape_single_quotes(column.data_type)),
                        wrap_string_with_quotes(dbt.escape_single_quotes(tojson(column.constraints))),
                        column.constraints | selectattr('type', 'equalto', 'not_null') | list | length > 0,
                        column.constraints | length,
                        wrap_string_with_quotes(dbt.escape_single_quotes(column.quote))
                    ]
                %}

                {%- do values.append(values_line) -%}

            {%- endfor -%}
        {%- endfor -%}
    {{ return(values) }}

    {%- endif -%}
  
{%- endmacro -%}
