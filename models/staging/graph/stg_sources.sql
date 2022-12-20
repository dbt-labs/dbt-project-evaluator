
{{
    config(
        materialized='insert_graph_values',
        resource='sources'
    )
}}


    unique_id {{ dbt.type_string() }},
    name {{ dbt.type_string() }},
    file_path {{ dbt.type_string() }},
    alias {{ dbt.type_string() }},
    resource_type {{ dbt.type_string() }},
    source_name {{ dbt.type_string() }},
    is_source_described boolean,
    is_described boolean,
    is_enabled boolean,
    loaded_at_field {{ dbt.type_string() }},
    database {{ dbt.type_string() }},
    schema {{ dbt.type_string() }},
    package_name {{ dbt.type_string() }},
    loader {{ dbt.type_string() }},
    identifier {{ dbt.type_string() }},
    meta {{ dbt.type_string() }} 
    
              