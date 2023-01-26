{{
    config(
        materialized='table',
        post_hook="{{ generate_insert_statements_post_hook(this, resource_type='exposures', relationships=True) }}"
    )
}}

/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
) 

select 
    cast(null as {{ dbt.type_string()}}) as resource_id,
    cast(null as {{ dbt.type_string()}}) as direct_parent_id,
    cast(True as boolean) as is_primary_relationship

from dummy_cte
where false