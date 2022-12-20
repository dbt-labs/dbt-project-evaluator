
{{
    config(
        materialized='insert_graph_values',
        resource='sources'
    )
}}


-- define schema
select 
    cast('unique_id' as {{ dbt.type_string() }}) as unique_id,
    cast('name' as {{ dbt.type_string() }}) as name,
    cast('file_path' as {{ dbt.type_string() }}) as file_path,
    cast('alias' as {{ dbt.type_string() }}) as alias,
    cast('resource_type' as {{ dbt.type_string() }}) as resource_type,
    cast('source_name' as {{ dbt.type_string() }}) as source_name,
    cast(True as boolean) as is_source_described,
    cast(True as boolean) as is_described,
    cast(True as boolean) as is_enabled,
    cast('loaded_at_field' as {{ dbt.type_string() }}) as loaded_at_field,
    cast('database' as {{ dbt.type_string() }}) as database,
    cast('schema' as {{ dbt.type_string() }}) as schema,
    cast('package_name' as {{ dbt.type_string() }}) as package_name,
    cast('loader' as {{ dbt.type_string() }}) as loader,
    cast('identifier' as {{ dbt.type_string() }}) as identifier,
    cast('meta' as {{ dbt.type_string() }}) as meta
    

              