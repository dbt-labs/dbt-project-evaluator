

{{
    config(
        materialized='table',
        post_hook="{{ generate_insert_statements_post_hook(this, resource_type='exposures', relationships=True) }}"
    )
}}

select 

    cast(null as {{ dbt.type_string()}}) as resource_id,
    cast(null as {{ dbt.type_string()}}) as direct_parent_id,
    cast(True as boolean) as is_primary_relationship

where false