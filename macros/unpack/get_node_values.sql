{%- macro get_node_values() -%}
    {{ return(adapter.dispatch('get_node_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_node_values() -%}

    {%- if execute -%}
    {% set re = modules.re %}
    {%- set nodes_list = graph.nodes.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

        {%- set hard_coded_references = dbt_project_evaluator.find_all_hard_coded_references(node) -%}

        {%- set ns = namespace(exclude=false) -%}
        {%- set node_path = node.original_file_path | replace("\\","\\\\") -%}

        {#- we exclude the node if it is from the current project and matches the pattern -#}
        {%- for exclude_paths_pattern in var('exclude_paths_from_project',[]) -%}
            {%- set matched_path = re.search(exclude_paths_pattern, node_path, re.IGNORECASE) -%}
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

        {%- set values_line  = 
            [
                wrap_string_with_quotes(node.unique_id),
                wrap_string_with_quotes(node.name),
                wrap_string_with_quotes(node.resource_type),
                wrap_string_with_quotes(node.original_file_path | replace("\\","\\\\")),
                "cast(" ~ node.config.enabled | trim ~ " as boolean)",
                wrap_string_with_quotes(node.config.materialized),
                wrap_string_with_quotes(node.config.on_schema_change),
                wrap_string_with_quotes(node.database),
                wrap_string_with_quotes(node.schema),
                wrap_string_with_quotes(node.package_name),
                wrap_string_with_quotes(node.alias),
                "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as boolean)",
                "''" if not node.column_name else wrap_string_with_quotes(dbt.escape_single_quotes(node.column_name)),
                wrap_string_with_quotes(node.meta | tojson),
                wrap_string_with_quotes(dbt.escape_single_quotes(hard_coded_references)),
                wrap_string_with_quotes(node.get('depends_on',{}).get('macros',[]) | tojson),
                "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.test_metadata) | trim ~ " as boolean)",
                "cast(" ~ ns.exclude ~ " as boolean)",
            ]
        %}

        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}
