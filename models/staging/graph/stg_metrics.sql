
{{
    config(
        materialized='insert_graph_values',
        resource='metrics'
    )
}}


-- define schema
    unique_id {{ dbt.type_string() }},
    name {{ dbt.type_string() }},
    resource_type {{ dbt.type_string() }},
    file_path {{ dbt.type_string() }},
    is_described boolean,
    metric_type {{ dbt.type_string() }},
    model {{ dbt.type_string() }},
    label {{ dbt.type_string() }},
    sql {{ dbt.type_string() }},
    timestamp {{ dbt.type_string() }},
    package_name {{ dbt.type_string() }},
    dimensions {{ dbt.type_string() }},
    filters {{ dbt.type_string() }},
    meta {{ dbt.type_string() }}
    