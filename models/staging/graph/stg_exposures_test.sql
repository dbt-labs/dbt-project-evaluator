

{{
    config(
        materialized='insert_values',
        resource='exposure'
    )
}}


-- define schema
select 
    'unique_id' as unique_id, 
    'name' as name, 
    'resource_type' as resource_type,
    'file_path' as file_path, 
    True as is_described,
    'exposure_type' as exposure_type, 
    'maturity' as maturity, 
    'package_name' as package_name, 
    'url' as url,
    'owner_name' as owner_name,
    'owner_email' as owner_email,
    'meta' as meta
    
