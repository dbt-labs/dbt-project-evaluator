{% macro get_sources() %}
    {{ return(adapter.dispatch('get_sources', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__get_sources() %}

    {% if execute %}
    {% set nodes_list = graph.sources.values() %}
    {% set values = [] %}
    {% if nodes_list | length > 0 %}

        {% for node in nodes_list %}

            {% set values_line %}
                
                '{{ node.unique_id }}', 
                '{{ node.name }}',
                '{{ node.original_file_path }}',
                '{{ node.alias }}',
                '{{ node.resource_type }}',
                '{{ node.source_name }}',
                cast('{{ dbt_project_evaluator.is_not_empty_string(node.source_description) | trim }}' as boolean),
                cast('{{ dbt_project_evaluator.is_not_empty_string(node.description) | trim }}' as boolean),
                cast('{{ node.config.enabled }}' as boolean),
                '{{ node.loaded_at_field | replace("'", "_") }}}}',
                '{{ node.database }}',
                '{{ node.schema }}',
                '{{ node.package_name }}',
                '{{ node.loader }}',
                '{{ node.identifier }}'

            {% endset %}
            {% do values.append(values_line) %}

        {% endfor %}



        {{ return(
            dbt_project_evaluator.select_from_values(
                values = values,
                column_names = [
                'unique_id',
                'name',
                'file_path',
                'alias',
                'resource_type',
                'source_name',
                'is_source_described',
                'is_described',
                'is_enabled',
                'loaded_at_field',
                'database',
                'schema',
                'package_name',
                'loader',
                'identifier' 
                ]
            )
        ) }}

    {% else %}
        select 
            cast(null as {{ dbt_utils.type_string() }}) as unique_id,
            cast(null as {{ dbt_utils.type_string() }}) as name,
            cast(null as {{ dbt_utils.type_string() }}) as file_path,
            cast(null as {{ dbt_utils.type_string() }}) as alias,
            cast(null as {{ dbt_utils.type_string() }}) as resource_type,
            cast(null as {{ dbt_utils.type_string() }}) as source_name,
            cast(null as boolean) as is_source_described,
            cast(null as boolean) as is_described,
            cast(null as boolean) as is_enabled,
            cast(null as {{ dbt_utils.type_string() }}) as loaded_at_field,
            cast(null as {{ dbt_utils.type_string() }}) as database,
            cast(null as {{ dbt_utils.type_string() }}) as schema,
            cast(null as {{ dbt_utils.type_string() }}) as package_name,
            cast(null as {{ dbt_utils.type_string() }}) as loader,
            cast(null as {{ dbt_utils.type_string() }}) as identifier 


    {% endif %}
    
    {% endif %}
 
{% endmacro %}