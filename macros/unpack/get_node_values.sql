{%- macro get_node_values() -%}
    {{ return(adapter.dispatch('get_node_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_node_values() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.nodes.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

        {%- set hard_coded_references = dbt_project_evaluator.find_all_hard_coded_references(node) -%}
        {%- set contract = node.contract.enforced if node.contract else false -%}
        {%- set exclude_node = dbt_project_evaluator.set_is_excluded(node, resource_type="node") -%}


        {%- set values_line  = 
            [
                dbt.string_literal(node.unique_id),
                dbt.string_literal(node.name),
                dbt.string_literal(node.resource_type),
                dbt.string_literal(node.original_file_path | replace("\\","\\\\")),
                "cast(" ~ node.config.enabled | trim ~ " as boolean)",
                dbt.string_literal(node.config.materialized),
                dbt.string_literal(node.config.on_schema_change),
                dbt.string_literal(node.group),
                dbt.string_literal(node.access),
                dbt.string_literal(node.latest_version),
                "cast(" ~ contract | trim  ~ " as boolean)",
                node.columns.values() | list | length,
                node.columns.values() | list | selectattr('description') | list | length,
                dbt.string_literal(node.database),
                dbt.string_literal(node.schema),
                dbt.string_literal(node.package_name),
                dbt.string_literal(node.alias),
                "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as boolean)",
                "''" if not node.column_name else dbt.string_literal(dbt.escape_single_quotes(node.column_name)),
                dbt.string_literal(node.meta | tojson),
                dbt.string_literal(dbt.escape_single_quotes(hard_coded_references)),
                dbt.string_literal(node.get('depends_on',{}).get('macros',[]) | tojson),
                "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.test_metadata) | trim ~ " as boolean)",
                "cast(" ~ exclude_node ~ " as boolean)",
            ]
        %}

        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}
