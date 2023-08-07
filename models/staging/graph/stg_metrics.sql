{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='metrics') }}"
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
    cast(True as boolean) as is_described,
    cast(null as {{ dbt.type_string() }}) as metric_type,
    cast(null as {{ dbt.type_string() }}) as label,
    cast(null as {{ dbt.type_string() }}) as package_name,
    cast(null as {{ dbt.type_string() }}) as metric_filter,
    cast(null as {{ dbt.type_string() }}) as metric_measure,
    cast(null as {{ dbt.type_string() }}) as metric_measure_alias,
    cast(null as {{ dbt.type_string() }}) as numerator,
    cast(null as {{ dbt.type_string() }}) as denominator,
    cast(null as {{ dbt.type_string() }}) as expr,
    cast(null as {{ dbt.type_string() }}) as metric_window,
    cast(null as {{ dbt.type_string() }}) as grain_to_date,
    cast(null as {{ dbt.type_string() }}) as meta

from dummy_cte
where false 