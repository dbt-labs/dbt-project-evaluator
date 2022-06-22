{{
    config(
        materialized='table'
    )
}}

select 
    lower('False') = 'true' as is_source_described

union all 

select 
    cast('0' as boolean) as is_source_described