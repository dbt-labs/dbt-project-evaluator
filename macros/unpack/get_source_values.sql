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
        {%- set node_path_and_name = node.original_file_path | replace("\\","\\\\") ~ ":" ~ node.fqn[-2] ~ "." ~ node.fqn[-1] -%}

        {#- we exclude the source if it is from the current project and matches the pattern -#}
        {%- for exclude_pattern in var('exclude_paths_from_project',[]) -%}
            {%- set matched_path = re.search(exclude_pattern, node_path_and_name, re.IGNORECASE) -%}
            {%- if matched_path and node.package_name == project_name %}
                {% set ns.exclude = true %}
            {%- endif -%}
        {%- endfor -%}

        {#- we exclude the node if the package if it is listed in `exclude_packages` or if it is "all" -#}
        {%- if (
            node.package_name != project_name) 
            and (node.package_name in  var('exclude_packages',[]) or 'all' in var('exclude_packages',[])) 
        -%}
            {% set ns.exclude = true %}
        {%- endif -%}

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