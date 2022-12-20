
{{
    config(
        materialized='insert_graph_values',
        resource='nodes',
        relationships=True
    )
}}

select
    cast('resource_id' as {{ dbt.type_string()}}) as  resource_id,
    cast('direct_parent_id' as {{ dbt.type_string()}}) as  direct_parent_id,
    cast(True as boolean) as is_primary_relationship