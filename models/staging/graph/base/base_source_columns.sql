{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='sources', columns=True) }}"
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
    cast(null as {{ dbt_project_evaluator.type_string_dpe() }}) as node_unique_id,
    cast(null as {{ dbt_project_evaluator.type_string_dpe()}}) as name,
    cast(null as {{ dbt_project_evaluator.type_large_string()}}) as description,
    cast(null as {{ dbt_project_evaluator.type_string_dpe()}}) as data_type,
    cast(null as {{ dbt_project_evaluator.type_string_dpe()}}) as constraints,
    cast(True as boolean) as has_not_null_constraint,
    cast(0 as {{ dbt.type_int() }}) as constraints_count,
    cast(null as {{ dbt_project_evaluator.type_string_dpe()}}) as quote

from dummy_cte
where false