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
    cast(True as {{ dbt.type_boolean() }}) as is_enabled,
    cast(null as {{ dbt.type_string() }}) as materialized,
    cast(null as {{ dbt.type_string() }}) as on_schema_change,
    cast(null as {{ dbt.type_string() }}) as model_group,
    cast(null as {{ dbt.type_string() }}) as access,
    cast(null as {{ dbt.type_string() }}) as latest_version,
    cast(null as {{ dbt.type_string() }}) as version,
    cast(null as {{ dbt.type_string() }}) as deprecation_date,
    cast(True as {{ dbt.type_boolean() }}) as is_contract_enforced,
    cast(0 as {{ dbt.type_int() }}) as total_defined_columns,
    cast(0 as {{ dbt.type_int() }}) as total_described_columns,
    cast(null as {{ dbt.type_string() }}) as database,
    cast(null as {{ dbt.type_string() }}) as schema,
    cast(null as {{ dbt.type_string() }}) as package_name,
    cast(null as {{ dbt.type_string() }}) as alias,
    cast(True as {{ dbt.type_boolean() }}) as is_described,
    cast(null as {{ dbt.type_string() }}) as column_name,
    cast(null as {{ dbt.type_string() }}) as meta,
    cast(null as {{ dbt.type_string() }}) as hard_coded_references,
    cast(null as {{ dbt.type_int() }}) as number_lines,
    cast(null as {{ dbt.type_float() }}) as sql_complexity,
    cast(null as {{ dbt.type_string() }}) as macro_dependencies,
    cast(True as {{ dbt.type_boolean() }}) as is_generic_test,
    cast(True as {{ dbt.type_boolean() }}) as is_excluded

from dummy_cte
where false 
