-- one row for each resource in the graph
with unioned as (

    {{ dbt_utils.union_relations([
        ref('base__nodes'),
        ref('base__exposures'),
        ref('base__metrics'),
        ref('base__sources')
    ])}}

),

final as (

    select
        unique_id as resource_id, 
        case 
            when resource_type = 'source' then source_name || '.' || name
            else name 
        end as resource_name, 
        resource_type, 
        file_path, 
        case 
            when resource_type in ('test', 'source', 'metric', 'exposure') then null
            when file_path like '%{{ var('staging_folder_name', 'staging') }}%' or name like '%staging%' or name like '%stg%' then 'staging'
            when file_path like '%{{ var('intermediate_folder_name', 'intermediate') }}%' or name like '%intermediate%' or name like '%int%' then 'intermediate'
            when file_path like '%{{ var('marts_folder_name', 'marts') }}%' or name like '%fct%' or name like '%dim%' then 'marts'
            else 'other' -- is this the catch-all that we want? what about the reports folder in our example DAG?
        end as model_type, 
        is_enabled as is_enabled, 
        materialized as materialized, 
        on_schema_change as on_schema_change, 
        database as database, 
        schema as schema, 
        package_name as package_name, 
        alias as alias, 
        is_described as is_described, 
        exposure_type as exposure_type, 
        maturity as maturity, 
        url as url, 
        metric_type as metric_type, 
        model as model, 
        label as label, 
        sql as sql, 
        timestamp as timestamp,
        source_name as source_name, 
        is_source_described as is_source_described, 
        loaded_at_field as loaded_at_field, 
        loader as loader, 
        identifier as identifier

    from unioned
    where coalesce(is_enabled, True) = True
    and not(resource_type = 'model' and package_name = 'dbt_project_evaluator')

)

select * from final