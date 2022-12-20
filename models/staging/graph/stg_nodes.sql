
{{
    config(
        materialized='insert_graph_values',
        resource='nodes'
    )
}}


-- define schema 
    unique_id {{ dbt.type_string() }},
    name {{ dbt.type_string() }},
    resource_type {{ dbt.type_string() }},
    file_path {{ dbt.type_string() }},
    is_enabled boolean,
    materialized {{ dbt.type_string() }},
    on_schema_change {{ dbt.type_string() }},
    database {{ dbt.type_string() }},
    schema {{ dbt.type_string() }},
    package_name {{ dbt.type_string() }},
    alias {{ dbt.type_string() }},
    is_described boolean,
    column_name {{ dbt.type_string() }},
    meta {{ dbt.type_string() }},
    macro_dependencies {{ dbt.type_string() }},
    is_generic_test boolean
    

              