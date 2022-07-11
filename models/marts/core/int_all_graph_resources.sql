-- one row for each resource in the graph
with unioned as (

    {{ dbt_utils.union_relations([
        ref('stg_nodes'),
        ref('stg_exposures'),
        ref('stg_metrics'),
        ref('stg_sources')
    ])}}

),

naming_convention_prefixes as (
    select * from {{ ref('stg_naming_convention_prefixes') }}
), 

naming_convention_folders as (
    select * from {{ ref('stg_naming_convention_folders') }}
), 

unioned_with_calc as (
    select 
        *,
        case 
            when resource_type = 'source' then  {{ dbt_utils.concat(['source_name',"'.'",'name']) }}
            else name 
        end as resource_name,
        case
            when resource_type = 'source' then null
            else {{ dbt_utils.split_part('name', "'_'", 1) }}||'_' 
        end as prefix,
        {{ dbt_utils.replace("file_path", "regexp_replace(file_path,'.*/','')", "''") }} as directory_path,
        regexp_replace(file_path,'.*/','') as file_name 
    from unioned
    where coalesce(is_enabled, True) = True and package_name != 'dbt_project_evaluator'
), 

joined as (

    select
        unioned_with_calc.unique_id as resource_id, 
        unioned_with_calc.resource_name, 
        unioned_with_calc.prefix, 
        unioned_with_calc.resource_type, 
        unioned_with_calc.file_path, 
        unioned_with_calc.directory_path,
        unioned_with_calc.file_name,
        case 
            when unioned_with_calc.resource_type in ('test', 'source', 'metric', 'exposure', 'seed') then null
            else naming_convention_prefixes.model_type 
        end as model_type_prefix,
        case 
            when unioned_with_calc.resource_type in ('test', 'source', 'metric', 'exposure', 'seed') then null
            when {{ dbt_utils.position('naming_convention_folders.folder_name_value','unioned_with_calc.directory_path') }} = 0 then null
            else naming_convention_folders.model_type 
        end as model_type_folder,
        {{ dbt_utils.position('naming_convention_folders.folder_name_value','unioned_with_calc.directory_path') }} as position_folder,  
        nullif(unioned_with_calc.column_name, '') as column_name,
        unioned_with_calc.resource_name like 'unique%' and unioned_with_calc.resource_type = 'test' as is_not_null_test,
        unioned_with_calc.resource_name like 'not_null%' and unioned_with_calc.resource_type = 'test' as is_unique_test,
        unioned_with_calc.is_enabled, 
        unioned_with_calc.materialized, 
        unioned_with_calc.on_schema_change, 
        unioned_with_calc.database, 
        unioned_with_calc.schema, 
        unioned_with_calc.package_name, 
        unioned_with_calc.alias, 
        unioned_with_calc.is_described, 
        unioned_with_calc.exposure_type, 
        unioned_with_calc.maturity, 
        unioned_with_calc.url, 
        unioned_with_calc.owner_name,
        unioned_with_calc.owner_email,
        unioned_with_calc.meta,
        unioned_with_calc.metric_type, 
        unioned_with_calc.model, 
        unioned_with_calc.label, 
        unioned_with_calc.sql, 
        unioned_with_calc.timestamp as timestamp,  
        unioned_with_calc.source_name, -- NULL for non-source resources
        unioned_with_calc.is_source_described, 
        unioned_with_calc.loaded_at_field, 
        unioned_with_calc.loader, 
        unioned_with_calc.identifier

    from unioned_with_calc
    left join naming_convention_prefixes
        on unioned_with_calc.prefix = naming_convention_prefixes.prefix_value

    cross join naming_convention_folders   

), 

calculate_model_type as (
    select 
        *, 
        case 
            when resource_type in ('test', 'source', 'metric', 'exposure', 'seed') then null
            -- by default we will define the model type based on its prefix in the case prefix and folder types are different
            else coalesce(model_type_prefix, model_type_folder, 'other') 
        end as model_type,
        row_number() over (partition by resource_id order by position_folder desc) as folder_name_rank
    from joined
),

final as (
    select
        *
    from calculate_model_type
    where folder_name_rank = 1
)

select 
    *
from final
