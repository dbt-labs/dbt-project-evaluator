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

    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as unique_id,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as name,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as resource_type,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as file_path,
    cast(True as {{ dbt.type_boolean() }}) as is_enabled,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as materialized,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as on_schema_change,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as model_group,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as access,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as latest_version,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as version,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as deprecation_date,
    cast(True as {{ dbt.type_boolean() }}) as is_contract_enforced,
    cast(0 as {{ dbt.type_int() }}) as total_defined_columns,
    cast(0 as {{ dbt.type_int() }}) as total_described_columns,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as database,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as schema,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as package_name,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as alias,
    cast(True as {{ dbt.type_boolean() }}) as is_described,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as column_name,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as meta,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as hard_coded_references,
    cast(null as {{ dbt.type_int() }}) as number_lines,
    cast(null as {{ dbt.type_float() }}) as sql_complexity,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as macro_dependencies,
    cast(True as {{ dbt.type_boolean() }}) as is_generic_test,
    cast(True as {{ dbt.type_boolean() }}) as is_excluded

from dummy_cte
where false 
