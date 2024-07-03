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

    cast(null as {{ api.Column.string_type(600) }}) as unique_id,
    cast(null as {{ api.Column.string_type(600) }}) as name,
    cast(null as {{ api.Column.string_type(600) }}) as resource_type,
    cast(null as {{ api.Column.string_type(600) }}) as file_path,
    cast(True as boolean) as is_enabled,
    cast(null as {{ api.Column.string_type(600) }}) as materialized,
    cast(null as {{ api.Column.string_type(600) }}) as on_schema_change,
    cast(null as {{ api.Column.string_type(600) }}) as model_group,
    cast(null as {{ api.Column.string_type(600) }}) as access,
    cast(null as {{ api.Column.string_type(600) }}) as latest_version,
    cast(null as {{ api.Column.string_type(600) }}) as version,
    cast(null as {{ api.Column.string_type(600) }}) as deprecation_date,
    cast(True as boolean) as is_contract_enforced,
    cast(0 as {{ dbt.type_int() }}) as total_defined_columns,
    cast(0 as {{ dbt.type_int() }}) as total_described_columns,
    cast(null as {{ api.Column.string_type(600) }}) as database,
    cast(null as {{ api.Column.string_type(600) }}) as schema,
    cast(null as {{ api.Column.string_type(600) }}) as package_name,
    cast(null as {{ api.Column.string_type(600) }}) as alias,
    cast(True as boolean) as is_described,
    cast(null as {{ api.Column.string_type(600) }}) as column_name,
    cast(null as {{ api.Column.string_type(600) }}) as meta,
    cast(null as {{ api.Column.string_type(600) }}) as hard_coded_references,
    cast(null as {{ dbt.type_int() }}) as number_lines,
    cast(null as {{ dbt.type_float() }}) as sql_complexity,
    cast(null as {{ api.Column.string_type(600) }}) as macro_dependencies,
    cast(True as boolean) as is_generic_test,
    cast(True as boolean) as is_excluded

from dummy_cte
where false 