{%- macro get_source_values() -%}
    {{ return(adapter.dispatch('get_source_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_source_values() -%}

    {%- if execute -%}
    {% set re = modules.re %}
    {%- set nodes_list = graph.sources.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

        {%- set ns = namespace(exclude=false) -%}
        {%- set node_package_path = node.package_name ~ ":" ~ node.original_file_path | replace("\\","\\\\") ~ ":" ~ node.name -%}

        {%- for exclude_pattern in var('exclude_packages_and_paths',[]) -%}
            {%- set is_match = re.match(exclude_pattern, node_package_path, re.IGNORECASE) -%}
            {%- if is_match %}
                {% set ns.exclude = true %}
            {%- endif -%}
        {%- endfor -%}

         {%- set values_line = 
            [
              wrap_string_with_quotes(node.unique_id),
              wrap_string_with_quotes(node.name),
              wrap_string_with_quotes(node.original_file_path | replace("\\","\\\\")),
              wrap_string_with_quotes(node.alias),
              wrap_string_with_quotes(node.resource_type),
              wrap_string_with_quotes(node.source_name),
              "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.source_description) | trim ~ " as boolean)",
              "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as boolean)",
              "cast(" ~ node.config.enabled ~ " as boolean)",
              wrap_string_with_quotes(node.loaded_at_field | replace("'", "_")),
              wrap_string_with_quotes(node.database),
              wrap_string_with_quotes(node.schema),
              wrap_string_with_quotes(node.package_name),
              wrap_string_with_quotes(node.loader),
              wrap_string_with_quotes(node.identifier),
              wrap_string_with_quotes(node.meta | tojson),
              "cast(" ~ ns.exclude ~ " as boolean)",
            ]
        %}
            
        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}


    {{ return(values) }}
 
{%- endmacro -%}