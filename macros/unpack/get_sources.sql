{%- macro get_sources() -%}
    {{ return(adapter.dispatch('get_sources', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_sources() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.sources.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

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
              'file_path',
              'alias',
              'resource_type',
              'source_name',
              ('is_source_described', 'boolean'),
              ('is_described', 'boolean'),
              ('is_enabled', 'boolean'),
              'loaded_at_field',
              'database',
              'schema',
              'package_name',
              'loader',
              'identifier',
              'meta'
            ]
         )
    ) }}
 
{%- endmacro -%}