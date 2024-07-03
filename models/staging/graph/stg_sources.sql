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

    cast(null as {{ api.Column.string_type(600) }}) as unique_id,
    cast(null as {{ api.Column.string_type(600) }}) as name,
    cast(null as {{ api.Column.string_type(600) }}) as file_path,
    cast(null as {{ api.Column.string_type(600) }}) as alias,
    cast(null as {{ api.Column.string_type(600) }}) as resource_type,
    cast(null as {{ api.Column.string_type(600) }}) as source_name,
    cast(True as boolean) as is_source_described,
    cast(True as boolean) as is_described,
    cast(True as boolean) as is_enabled,
    cast(null as {{ api.Column.string_type(600) }}) as loaded_at_field,
    cast(null as {{ api.Column.string_type(600) }}) as database,
    cast(null as {{ api.Column.string_type(600) }}) as schema,
    cast(null as {{ api.Column.string_type(600) }}) as package_name,
    cast(null as {{ api.Column.string_type(600) }}) as loader,
    cast(null as {{ api.Column.string_type(600) }}) as identifier,
    cast(null as {{ api.Column.string_type(600) }})  as meta,
    cast(True as boolean) as is_excluded

from dummy_cte
where false