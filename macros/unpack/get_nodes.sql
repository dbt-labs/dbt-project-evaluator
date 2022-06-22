{% macro get_nodes() %}
    {{ return(adapter.dispatch('get_nodes', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__get_nodes() %}

    {% if execute %}
    {% set nodes_list = graph.nodes.values() %}
    {% if nodes_list | length > 0 %}
      
        {% set values = [] %}

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
                ]
            )
        ) }}

    {% else %}

        select 
            cast(null as {{ dbt_utils.type_string() }}) as unique_id,
            cast(null as {{ dbt_utils.type_string() }}) as name,
            cast(null as {{ dbt_utils.type_string() }}) as resource_type,
            cast(null as {{ dbt_utils.type_string() }}) as file_path,
            cast(null as boolean) as is_enabled,
            cast(null as {{ dbt_utils.type_string() }}) as materialized,
            cast(null as {{ dbt_utils.type_string() }}) as on_schema_change,
            cast(null as {{ dbt_utils.type_string() }}) as database,
            cast(null as {{ dbt_utils.type_string() }}) as schema,
            cast(null as {{ dbt_utils.type_string() }}) as package_name,
            cast(null as {{ dbt_utils.type_string() }}) as alias,
            cast(null as boolean) as is_described,
            cast(null as {{ dbt_utils.type_string() }}) as column_name
    
        where false
    
    {% endif %}

    {% endif %}

{% endmacro %}
