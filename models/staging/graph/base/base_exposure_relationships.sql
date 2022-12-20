
{{
    config(
        materialized='insert_graph_values',
        resource='exposures',
        relationships=True
    )
}}

    resource_id {{ dbt.type_string()}},
    direct_parent_id {{ dbt.type_string()}},
    is_primary_relationship boolean