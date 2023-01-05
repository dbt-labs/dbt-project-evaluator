
{{
    config(
        materialized='table',
        post_hook="{{ generate_insert_statements_post_hook(this, resource_type='exposures') }}"
    )
}}

select 
-- define schema
    cast(null as {{ dbt.type_string() }} ) as unique_id,
    cast(null as {{ dbt.type_string() }} ) as name,
    cast(null as {{ dbt.type_string() }} ) as resource_type,
    cast(null as {{ dbt.type_string() }} ) as file_path,
    cast(True as boolean) as is_described,
    cast(null as {{ dbt.type_string() }} ) as exposure_type,
    cast(null as {{ dbt.type_string() }} ) as maturity,
    cast(null as {{ dbt.type_string() }} ) as package_name,
    cast(null as {{ dbt.type_string() }} ) as url,
    cast(null as {{ dbt.type_string() }} ) as owner_name,
    cast(null as {{ dbt.type_string() }} ) as owner_email,
    cast(null as {{ dbt.type_string() }} ) as meta

where false 