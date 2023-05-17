{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='nodes') }}"
    )
}}

{% if execute %}
    {{ check_model_is_table(model) }}
{% endif %}

/* Bigquery won't let us `where` without `from` so we use this workaround */
with dummy_cte as (
    select 1 as foo
)

select 

    cast(null as {{ dbt.type_string() }}) as unique_id,
    cast(null as {{ dbt.type_string() }}) as name,
    cast(null as {{ dbt.type_string() }}) as resource_type,
    cast(null as {{ dbt.type_string() }}) as file_path,
    cast(True as boolean) as is_enabled,
    cast(null as {{ dbt.type_string() }}) as materialized,
    cast(null as {{ dbt.type_string() }}) as on_schema_change,
    cast(null as {{ dbt.type_string() }}) as database,
    cast(null as {{ dbt.type_string() }}) as schema,
    cast(null as {{ dbt.type_string() }}) as package_name,
    cast(null as {{ dbt.type_string() }}) as alias,
    cast(True as boolean) as is_described,
    cast(null as {{ dbt.type_string() }}) as column_name,
    cast(null as {{ dbt.type_string() }}) as meta,
    cast(null as {{ dbt.type_string() }}) as hard_coded_references,
    cast(null as {{ dbt.type_string() }}) as macro_dependencies,
    cast(True as boolean) as is_generic_test,
    cast(True as boolean) as is_excluded

from dummy_cte
where false 