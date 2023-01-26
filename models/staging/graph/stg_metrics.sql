{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='metrics') }}"
    )
}}

/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select 

    cast(null as {{ dbt.type_string() }}) as unique_id,
    cast(null as {{ dbt.type_string() }}) as name,
    cast(null as {{ dbt.type_string() }}) as resource_type,
    cast(null as {{ dbt.type_string() }}) as file_path,
    cast(True as boolean) as is_described,
    cast(null as {{ dbt.type_string() }}) as metric_type,
    cast(null as {{ dbt.type_string() }}) as model,
    cast(null as {{ dbt.type_string() }}) as label,
    cast(null as {{ dbt.type_string() }}) as sql,
    cast(null as {{ dbt.type_string() }}) as timestamp,
    cast(null as {{ dbt.type_string() }}) as package_name,
    cast(null as {{ dbt.type_string() }}) as dimensions,
    cast(null as {{ dbt.type_string() }}) as filters,
    cast(null as {{ dbt.type_string() }}) as meta

from dummy_cte
where false 