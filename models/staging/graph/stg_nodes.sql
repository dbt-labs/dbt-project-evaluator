
{{
    config(
        materialized='insert_graph_values',
        resource='nodes'
    )
}}


-- define schema
select 
    cast('unique_id' as {{ dbt.type_string() }}) as unique_id,
    cast('name' as {{ dbt.type_string() }}) as name,
    cast('resource_type' as {{ dbt.type_string() }}) as resource_type,
    cast('file_path' as {{ dbt.type_string() }}) as file_path,
    cast(True as boolean) as is_enabled,
    cast('materialized' as {{ dbt.type_string() }}) as materialized,
    cast('on_schema_change' as {{ dbt.type_string() }}) as on_schema_change,
    cast('database' as {{ dbt.type_string() }}) as database,
    cast('schema' as {{ dbt.type_string() }}) as schema,
    cast('package_name' as {{ dbt.type_string() }}) as package_name,
    cast('alias' as {{ dbt.type_string() }}) as alias,
    cast(True as boolean) as is_described,
    cast('column_name' as {{ dbt.type_string() }}) as column_name,
    cast('meta' as {{ dbt.type_string() }}) as meta,
    cast('macro_dependencies' as {{ dbt.type_string() }}) as macro_dependencies,
    cast(True as boolean) as is_generic_test
    

              