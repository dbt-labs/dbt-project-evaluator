-- one row for each node in the graph
with 

unioned as (

    {{ dbt_utils.union_relations([
        ref('base__nodes'),
        ref('base__exposures'),
        ref('base__metrics'),
        ref('base__sources')
    ])}}

)

select
    unique_id as node_id, 
    node_name, 
    resource_type, 
    file_path, 
    is_enabled, 
    materialized, 
    on_schema_change, 
    database, 
    schema, 
    package_name, 
    alias, 
    is_described, 
    exposure_type, 
    maturity, 
    url, 
    metric_type, 
    model, 
    label, 
    sql, 
    timestamp, 
    node, 
    source_name, 
    is_source_described, 
    loaded_at_field, 
    loader, 
    identifier

from unioned
where coalesce(is_enabled, True) = True