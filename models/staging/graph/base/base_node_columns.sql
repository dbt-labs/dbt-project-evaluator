{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='nodes', columns=True) }}"
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
    cast(null as {{ api.Column.string_type(600) }}) as node_unique_id,
    cast(null as {{ api.Column.string_type(600)}}) as name,
    cast(null as {{ dbt_project_evaluator.type_large_string()}}) as description,
    cast(null as {{ api.Column.string_type(600)}}) as data_type,
    cast(null as {{ api.Column.string_type(600)}}) as constraints,
    cast(True as boolean) as has_not_null_constraint,
    cast(0 as {{ dbt.type_int() }}) as constraints_count,
    cast(null as {{ api.Column.string_type(600)}}) as quote

from dummy_cte
where false
