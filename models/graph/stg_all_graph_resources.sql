-- one row for each resource in the graph
with unioned as (

    {{ dbt_utils.union_relations([
        ref('base__nodes'),
        ref('base__exposures'),
        ref('base__metrics'),
        ref('base__sources')
    ])}}

),

naming_convention_prefixes as (
    select * from {{ ref('stg_naming_convention_prefixes') }}
), 

naming_convention_folders as (
    select * from {{ ref('stg_naming_convention_folders') }}
), 

joined as (

    select
        unioned.unique_id as resource_id, 
        case 
            when unioned.resource_type = 'source' then  {{ dbt_utils.concat(['unioned.source_name',"'.'",'unioned.name']) }}
            else name 
        end as resource_name, 
        unioned.resource_type, 
        unioned.file_path, 
        naming_convention_prefixes.model_type as model_type_prefix,
        naming_convention_folders.model_type as model_type_folder,
        {{ dbt_utils.position('naming_convention_folders.model_type','unioned.file_path') }} as position_folder,  
        unioned.is_enabled, 
        unioned.materialized, 
        unioned.on_schema_change, 
        unioned.database, 
        unioned.schema, 
        unioned.package_name, 
        unioned.alias, 
        unioned.is_described, 
        unioned.exposure_type, 
        unioned.maturity, 
        unioned.url, 
        unioned.metric_type, 
        unioned.model, 
        unioned.label, 
        unioned.sql, 
        unioned.timestamp as timestamp,  
        unioned.source_name, -- NULL for non-source resources
        unioned.is_source_described, 
        unioned.loaded_at_field, 
        unioned.loader, 
        unioned.identifier

    from unioned
    left join naming_convention_prefixes
        on unioned.name like {{ dbt_utils.concat(['naming_convention_prefixes.prefix_value',"'_%'"]) }}

    left join naming_convention_folders
        on {{ dbt_utils.concat(["'/'",'unioned.file_path']) }} like {{ dbt_utils.concat(["'%/'",'naming_convention_folders.folder_name_value',"'/%'"]) }}
    
    where coalesce(unioned.is_enabled, True) = True
    and not(unioned.resource_type = 'model' and unioned.package_name = 'dbt_project_evaluator')

), 

final as (
    select 
        joined.*, 
        case 
            when resource_type in ('test', 'source', 'metric', 'exposure', 'seed') then null
            else coalesce(model_type_prefix, model_type_folder, 'other') 
        end as model_type,
        row_number() over (partition by resource_id order by position_folder desc) as position_rk
    from joined
)

select 
    *
from final
where position_rk = 1