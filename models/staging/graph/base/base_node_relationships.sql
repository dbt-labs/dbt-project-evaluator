{{
    config(
        materialized='table',
        post_hook="{{ insert_resources_from_graph(this, resource_type='nodes', relationships=True) }}"
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
    cast(null as {{ dbt_project_evaluator.type_string_dpe()}}) as resource_id,
    cast(null as {{ dbt_project_evaluator.type_string_dpe()}}) as direct_parent_id,
    cast(True as {{ dbt.type_boolean() }}) as is_primary_relationship

from dummy_cte
where false
