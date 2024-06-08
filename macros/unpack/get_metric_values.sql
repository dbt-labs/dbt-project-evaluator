{%- macro get_metric_values() -%}
    {{ return(adapter.dispatch('get_metric_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_metric_values() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.metrics.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}
   
          {%- set values_line = 
            [
            wrap_string_with_quotes(node.unique_id),
            wrap_string_with_quotes(node.name),
            wrap_string_with_quotes(node.resource_type),
            wrap_string_with_quotes(node.original_file_path | replace("\\","\\\\")),
            "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as " ~ dbt.type_boolean() ~ ")",
            wrap_string_with_quotes(node.type),
            wrap_string_with_quotes(dbt.escape_single_quotes(node.label)),
            wrap_string_with_quotes(node.package_name),
            wrap_string_with_quotes(dbt.escape_single_quotes(tojson(node.filter))),
            wrap_string_with_quotes(node.type_params.measure.name),
            wrap_string_with_quotes(node.type_params.measure.alias),
            wrap_string_with_quotes(node.type_params.numerator | tojson),
            wrap_string_with_quotes(node.type_params.denominator | tojson),
            wrap_string_with_quotes(node.type_params.expr),
            wrap_string_with_quotes(node.type_params.window | tojson),
            wrap_string_with_quotes(node.type_params.grain_to_date),
            wrap_string_with_quotes(node.meta | tojson)
            ]
          %}

        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}
