
{{
    config(
        materialized='insert_graph_values',
        resource='exposures'
    )
}}


-- define schema
select 
    cast('unique_id' as {{ dbt.type_string() }}) as unique_id, 
    cast('name' as {{ dbt.type_string() }}) as name, 
    cast('resource_type' as {{ dbt.type_string() }}) as resource_type,
    cast('file_path' as {{ dbt.type_string() }}) as file_path, 
    cast(True as boolean) as is_described,
    cast('exposure_type' as {{ dbt.type_string() }}) as exposure_type, 
    cast('maturity' as {{ dbt.type_string() }}) as maturity, 
    cast('package_name' as {{ dbt.type_string() }}) as package_name, 
    cast('url' as {{ dbt.type_string() }}) as url,
    cast('owner_name' as {{ dbt.type_string() }}) as owner_name,
    cast('owner_email' as {{ dbt.type_string() }}) as owner_email,
    cast('meta' as {{ dbt.type_string() }}) as meta