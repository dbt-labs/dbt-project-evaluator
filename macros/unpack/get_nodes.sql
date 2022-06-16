{% macro get_nodes() %}
    {{ return(adapter.dispatch('get_nodes', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__get_nodes() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() %}
    {% set values = [] %}

    {% set values0 %}

              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as boolean),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as {{ dbt_utils.type_string() }}),
              cast(null as boolean),
              cast(null as {{ dbt_utils.type_string() }})

    {% endset %}
    {% do values.append(values0) %}


    {% for node in nodes_list %}

          {% set values_line %}

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
              '{{ "" if not node.column_name else node.column_name }}'

        {% endset %}
        {% do values.append(values_line) %}

    {% endfor %}
    {% endif %}

    {{ return(
        dbt_project_evaluator.select_from_values(
            values = values,
            column_names = [
              'unique_id',
              'name',
              'resource_type',
              'file_path',
              'is_enabled',
              'materialized',
              'on_schema_change',
              'database',
              'schema',
              'package_name',
              'alias',
              'is_described',
              'column_name'
            ],
            where_condition='unique_id is not null'
         )
    ) }}

{% endmacro %}
