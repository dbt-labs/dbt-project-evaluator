{{
    config(
        materialized='table',
    )
}}

{% if execute %}
    {{ check_model_is_table(model) }}
{% endif %}

with unioned as (

    {{ dbt_utils.union_relations([
        ref('base_node_columns'),
        ref('base_source_columns')
    ])}}
)

select distinct * from unioned