{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='sources') }}"
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
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as file_path,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as alias,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as resource_type,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as source_name,
    cast(True as {{ dbt.type_boolean() }}) as is_source_described,
    cast(True as {{ dbt.type_boolean() }}) as is_described,
    cast(True as {{ dbt.type_boolean() }}) as is_enabled,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as loaded_at_field,
    cast(True as {{ dbt.type_boolean() }}) as is_freshness_enabled,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as database,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as schema,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as package_name,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as loader,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as identifier,
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }})  as meta,
    cast(True as {{ dbt.type_boolean() }}) as is_excluded

from dummy_cte
where false
