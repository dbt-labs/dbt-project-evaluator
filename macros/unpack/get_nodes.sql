{%- macro get_nodes() -%}
    {{ return(adapter.dispatch('get_nodes', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_nodes() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.nodes.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

          {%- set values_line %}

              '{{ node.unique_id }}',
              '{{ node.name }}',
              '{{ node.resource_type }}',
              '{{ node.original_file_path }}',
              cast('{{ node.config.enabled | trim }}' as boolean),
              '{{ node.config.materialized }}',
              '{{ node.config.on_schema_change}}',
              '{{ node.database }}',
              '{{ node.schema }}',
              '{{ node.package_name }}',
              '{{ node.alias }}',
              cast('{{ dbt_project_evaluator.is_not_empty_string(node.description) | trim }}' as boolean),
              '{{ "" if not node.column_name else node.column_name }}',
              '{{ node.meta | tojson }}'

        {% endset -%}
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
