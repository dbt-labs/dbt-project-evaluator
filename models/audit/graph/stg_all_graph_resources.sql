-- one row for each node in the graph
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
            when file_path like '%{{ var('staging_folder_name', 'staging') }}%' or resource_name like '%staging%' or resource_name like '%stg%' then 'staging'
            when file_path like '%{{ var('marts_folder_name', 'marts') }}%' then 'marts'
            else 'intermediate'
        end as model_type, 
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
        source_name, 
        is_source_described, 
        loaded_at_field, 
        loader, 
        identifier

    from unioned
    where coalesce(is_enabled, True) = True
    and not(resource_type = 'model' and package_name = 'pro_serv_dag_auditing')

)

select * from final