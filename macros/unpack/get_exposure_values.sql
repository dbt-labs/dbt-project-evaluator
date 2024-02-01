{%- macro get_exposure_values() -%}
    {{ return(adapter.dispatch('get_exposure_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_exposure_values() -%}

    {%- if execute -%}

        {%- set nodes_list = graph.exposures.values() -%}
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
              dbt.string_literal(node.maturity),
              dbt.string_literal(node.package_name),
              dbt.string_literal(node.url),
              dbt.string_literal(dbt.escape_single_quotes(node.owner.name)),
              dbt.string_literal(dbt.escape_single_quotes(node.owner.email)),
              dbt.string_literal(node.meta | tojson)
            ]
          %}

          {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}