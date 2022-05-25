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

unioned_with_prefix as (
    select 
        *,
        case 
            when unioned.resource_type = 'source' then  {{ dbt_utils.concat(['unioned.source_name',"'.'",'unioned.name']) }}
            else name 
        end as resource_name,
        case
            when unioned.resource_type = 'source' then null
            else {{ dbt_utils.split_part('name', "'_'", 1) }}||'_' 
        end as prefix,
        {{ dbt_utils.concat(["'/'",'unioned.file_path']) }} as file_path_prefixed_with_slash

    from unioned
), 

joined as (

    select
        unioned_with_prefix.unique_id as resource_id, 
        unioned_with_prefix.resource_name, 
        unioned_with_prefix.prefix, 
        unioned_with_prefix.resource_type, 
        unioned_with_prefix.file_path, 
        naming_convention_prefixes.model_type as model_type_prefix,
        naming_convention_folders.model_type as model_type_folder,
        {{ dbt_utils.position('naming_convention_folders.model_type','unioned_with_prefix.file_path_prefixed_with_slash') }} as position_folder,  
        nullif(column_name, '') as column_name,
        resource_name like 'unique%' and resource_type = 'test' as is_not_null_test,
        resource_name like 'not_null%' and resource_type = 'test' as is_unique_test,
        unioned_with_prefix.is_enabled, 
        unioned_with_prefix.materialized, 
        unioned_with_prefix.on_schema_change, 
        unioned_with_prefix.database, 
        unioned_with_prefix.schema, 
        unioned_with_prefix.package_name, 
        unioned_with_prefix.alias, 
        unioned_with_prefix.is_described, 
        unioned_with_prefix.exposure_type, 
        unioned_with_prefix.maturity, 
        unioned_with_prefix.url, 
        unioned_with_prefix.metric_type, 
        unioned_with_prefix.model, 
        unioned_with_prefix.label, 
        unioned_with_prefix.sql, 
        unioned_with_prefix.timestamp as timestamp,  
        unioned_with_prefix.source_name, -- NULL for non-source resources
        unioned_with_prefix.is_source_described, 
        unioned_with_prefix.loaded_at_field, 
        unioned_with_prefix.loader, 
        unioned_with_prefix.identifier

    from unioned_with_prefix
    left join naming_convention_prefixes
        on unioned_with_prefix.prefix = naming_convention_prefixes.prefix_value

    left join naming_convention_folders
        -- we added '/' at the front of the path, to be /folder1/folder2/folder3/mmodel_name.sql
        -- and we search for /naming_convention_folder/ ; this allows us to only match full folder names
        on file_path_prefixed_with_slash like {{ dbt_utils.concat(["'%/'",'naming_convention_folders.folder_name_value',"'/%'"]) }}
    
    where coalesce(unioned_with_prefix.is_enabled, True) = True
    and package_name != 'dbt_project_evaluator'
    and unioned_with_prefix.package_name != 'dbt_project_evaluator'

), 

final as (
    select 
        *, 
        case 
            when resource_type in ('test', 'source', 'metric', 'exposure', 'seed') then null
            -- by default we will define the model type based on its prefix in the case prefix and folder types are different
            else coalesce(model_type_prefix, model_type_folder, 'other') 
        end as model_type,
        row_number() over (partition by resource_id order by position_folder desc) as position_rk
    from joined
)

select 
    *
from final
where position_rk = 1
