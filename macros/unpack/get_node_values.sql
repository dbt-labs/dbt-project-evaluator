{%- macro get_node_values() -%}
    {{ return(adapter.dispatch('get_node_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_node_values() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.nodes.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

        {%- set hard_coded_references = dbt_project_evaluator.find_all_hard_coded_references(node) -%}
        {%- set number_lines = dbt_project_evaluator.calculate_number_lines(node) -%}
        {%- set sql_complexity = dbt_project_evaluator.calculate_sql_complexity(node) -%}
        {%- set contract = node.contract.enforced if node.contract else false -%}
        {%- set exclude_node = dbt_project_evaluator.set_is_excluded(node, resource_type="node") -%}


        {%- set values_line  = 
            [
                wrap_string_with_quotes(node.unique_id),
                wrap_string_with_quotes(node.name),
                wrap_string_with_quotes(node.resource_type),
                wrap_string_with_quotes(node.original_file_path | replace("\\","\\\\")),
                "cast(" ~ node.config.enabled | trim ~ " as " ~ dbt.type_boolean() ~ ")",
                wrap_string_with_quotes(node.config.materialized),
                wrap_string_with_quotes(node.config.on_schema_change),
                wrap_string_with_quotes(node.group),
                wrap_string_with_quotes(node.access),
                wrap_string_with_quotes(node.latest_version),
                wrap_string_with_quotes(node.version),
                wrap_string_with_quotes(node.deprecation_date),
                "cast(" ~ contract | trim  ~ " as " ~ dbt.type_boolean() ~ ")",
                node.columns.values() | list | length,
                node.columns.values() | list | selectattr('description') | list | length,
                wrap_string_with_quotes(node.database),
                wrap_string_with_quotes(node.schema),
                wrap_string_with_quotes(node.package_name),
                wrap_string_with_quotes(node.alias),
                "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as " ~ dbt.type_boolean() ~ ")",
                "''" if not node.column_name else wrap_string_with_quotes(dbt.escape_single_quotes(node.column_name)),
                wrap_string_with_quotes(node.meta | tojson),
                wrap_string_with_quotes(dbt.escape_single_quotes(hard_coded_references)),
                number_lines,
                sql_complexity,
                wrap_string_with_quotes(node.get('depends_on',{}).get('macros',[]) | tojson),
                "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.test_metadata) | trim ~ " as " ~ dbt.type_boolean() ~ ")",
                "cast(" ~ exclude_node ~ " as " ~ dbt.type_boolean() ~ ")",
            ]
        %}

        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}
