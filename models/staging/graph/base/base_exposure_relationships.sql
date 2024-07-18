{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='exposures', relationships=True) }}"
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
    cast(null as {{ api.Column.string_type(600)}}) as resource_id,
    cast(null as {{ api.Column.string_type(600)}}) as direct_parent_id,
    cast(True as boolean) as is_primary_relationship

from dummy_cte
where false