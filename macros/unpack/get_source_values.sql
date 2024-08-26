{%- macro get_source_values() -%}
    {{ return(adapter.dispatch('get_source_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_source_values() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.sources.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

        {%- set exclude_source = dbt_project_evaluator.set_is_excluded(node, resource_type="source") -%}

         {%- set values_line = 
            [
              wrap_string_with_quotes(node.unique_id),
              wrap_string_with_quotes(node.name),
              wrap_string_with_quotes(node.original_file_path | replace("\\","\\\\")),
              wrap_string_with_quotes(node.alias),
              wrap_string_with_quotes(node.resource_type),
              wrap_string_with_quotes(node.source_name),
              "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.source_description) | trim ~ " as " ~ dbt.type_boolean() ~ ")",
              "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as " ~ dbt.type_boolean() ~ ")",
              "cast(" ~ node.config.enabled ~ " as " ~ dbt.type_boolean() ~ ")",
              wrap_string_with_quotes(node.loaded_at_field | replace("'", "_")),
              "cast(" ~ ((node.freshness != None) and (dbt_project_evaluator.is_not_empty_string(node.freshness.warn_after.count) 
                or dbt_project_evaluator.is_not_empty_string(node.freshness.error_after.count))) | trim ~ " as boolean)",
              wrap_string_with_quotes(node.database),
              wrap_string_with_quotes(node.schema),
              wrap_string_with_quotes(node.package_name),
              wrap_string_with_quotes(node.loader),
              wrap_string_with_quotes(node.identifier),
              wrap_string_with_quotes(node.meta | tojson),
              "cast(" ~ exclude_source ~ " as " ~ dbt.type_boolean() ~ ")",
            ]
        %}
            
        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}


    {{ return(values) }}
 
{%- endmacro -%}
