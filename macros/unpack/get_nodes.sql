{%- macro get_nodes() -%}
    {{ return(adapter.dispatch('get_nodes', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_nodes() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.nodes.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

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
                "''" if not node.column_name else wrap_string_with_quotes(dbt_utils.escape_single_quotes(node.column_name)),
                wrap_string_with_quotes(node.meta | tojson)
            ]
        %}

        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(
        dbt_project_evaluator.select_from_values(
            values = values,
            columns = [
              'unique_id',
              'name',
              'resource_type',
              'file_path',
              ('is_enabled', 'boolean'),
              'materialized',
              'on_schema_change',
              'database',
              'schema',
              'package_name',
              'alias',
              ('is_described', 'boolean'),
              'column_name',
              'meta'
            ]
         )
    ) }}

{%- endmacro -%}
