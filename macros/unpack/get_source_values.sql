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
              dbt.string_literal(node.unique_id),
              dbt.string_literal(node.name),
              dbt.string_literal(node.original_file_path | replace("\\","\\\\")),
              dbt.string_literal(node.alias),
              dbt.string_literal(node.resource_type),
              dbt.string_literal(node.source_name),
              "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.source_description) | trim ~ " as boolean)",
              "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as boolean)",
              "cast(" ~ node.config.enabled ~ " as boolean)",
              dbt.string_literal(node.loaded_at_field | replace("'", "_")),
              dbt.string_literal(node.database),
              dbt.string_literal(node.schema),
              dbt.string_literal(node.package_name),
              dbt.string_literal(node.loader),
              dbt.string_literal(node.identifier),
              dbt.string_literal(node.meta | tojson),
              "cast(" ~ exclude_source ~ " as boolean)",
            ]
        %}
            
        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}


    {{ return(values) }}
 
{%- endmacro -%}