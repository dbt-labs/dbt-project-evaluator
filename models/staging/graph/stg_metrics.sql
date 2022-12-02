
{{
    config(
        materialized='insert_graph_values',
        resource='metrics'
    )
}}


-- define schema
select 
    cast('unique_id' as {{ dbt.type_string() }}) as unique_id, 
    cast('name' as {{ dbt.type_string() }}) as name, 
    cast('resource_type' as {{ dbt.type_string() }}) as resource_type, 
    cast('file_path' as {{ dbt.type_string() }}) as file_path, 
    cast(True as boolean) as is_described,
    cast('metric_type' as {{ dbt.type_string() }}) as metric_type, 
    cast('model' as {{ dbt.type_string() }}) as model,
    cast('label' as {{ dbt.type_string() }}) as label, 
    cast('sql' as {{ dbt.type_string() }}) as sql, 
    cast('timestamp' as {{ dbt.type_string() }}) as timestamp, 
    cast('package_name' as {{ dbt.type_string() }}) as package_name,
    cast('dimensions' as {{ dbt.type_string() }}) as dimensions,
    cast('filters' as {{ dbt.type_string() }}) as filters,
    cast('meta' as {{ dbt.type_string() }}) as meta
    