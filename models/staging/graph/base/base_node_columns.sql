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
    cast(null as {{ dbt.type_string() }}) as node_unique_id,
    cast(null as {{ dbt.type_string()}}) as name,
    cast(null as {{ dbt.type_string()}}) as description,
    cast(null as {{ dbt.type_string()}}) as data_type,
    cast(null as {{ dbt.type_string()}}) as quote

from dummy_cte
where false