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
            dbt.string_literal(node.unique_id),
            dbt.string_literal(node.name),
            dbt.string_literal(node.resource_type),
            dbt.string_literal(node.original_file_path | replace("\\","\\\\")),
            "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as boolean)",
            dbt.string_literal(node.type),
            dbt.string_literal(dbt.escape_single_quotes(node.label)),
            dbt.string_literal(node.package_name),
            dbt.string_literal(node.filter | tojson),
            dbt.string_literal(node.type_params.measure.name),
            dbt.string_literal(node.type_params.measure.alias),
            dbt.string_literal(node.type_params.numerator | tojson),
            dbt.string_literal(node.type_params.denominator | tojson),
            dbt.string_literal(node.type_params.expr),
            dbt.string_literal(node.type_params.window | tojson),
            dbt.string_literal(node.type_params.grain_to_date),
            dbt.string_literal(node.meta | tojson)
            ]
          %}

        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}
