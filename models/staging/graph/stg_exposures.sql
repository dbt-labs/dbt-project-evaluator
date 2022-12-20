
{{
    config(
        materialized='insert_graph_values',
        resource='exposures'
    )
}}


-- define schema
    unique_id {{ dbt.type_string() }},
    name {{ dbt.type_string() }},
    resource_type {{ dbt.type_string() }},
    file_path {{ dbt.type_string() }},
    is_described boolean,
    exposure_type {{ dbt.type_string() }},
    maturity {{ dbt.type_string() }},
    package_name {{ dbt.type_string() }},
    url {{ dbt.type_string() }},
    owner_name {{ dbt.type_string() }},
    owner_email {{ dbt.type_string() }},
    meta {{ dbt.type_string() }}