{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='exposures') }}"
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

    cast(null as {{ api.Column.string_type(600) }} ) as unique_id,
    cast(null as {{ api.Column.string_type(600) }} ) as name,
    cast(null as {{ api.Column.string_type(600) }} ) as resource_type,
    cast(null as {{ api.Column.string_type(600) }} ) as file_path,
    cast(True as boolean) as is_described,
    cast(null as {{ api.Column.string_type(600) }} ) as exposure_type,
    cast(null as {{ api.Column.string_type(600) }} ) as maturity,
    cast(null as {{ api.Column.string_type(600) }} ) as package_name,
    cast(null as {{ api.Column.string_type(600) }} ) as url,
    cast(null as {{ api.Column.string_type(600) }} ) as owner_name,
    cast(null as {{ api.Column.string_type(600) }} ) as owner_email,
    cast(null as {{ api.Column.string_type(600) }} ) as meta

from dummy_cte
where false 