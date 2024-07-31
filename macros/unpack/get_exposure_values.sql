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
              wrap_string_with_quotes(node.unique_id),
              wrap_string_with_quotes(node.name),
              wrap_string_with_quotes(node.resource_type),
              wrap_string_with_quotes(node.original_file_path | replace("\\","\\\\")),
              "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as " ~ dbt.type_boolean() ~ ")",
              wrap_string_with_quotes(node.type),
              wrap_string_with_quotes(node.maturity),
              wrap_string_with_quotes(node.package_name),
              wrap_string_with_quotes(node.url),
              wrap_string_with_quotes(dbt.escape_single_quotes(node.owner.name)),
              wrap_string_with_quotes(dbt.escape_single_quotes(node.owner.email)),
              wrap_string_with_quotes(node.meta | tojson)
            ]
          %}

          {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}
