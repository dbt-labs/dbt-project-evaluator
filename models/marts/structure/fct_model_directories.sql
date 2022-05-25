-- Because we often work with multiple data sources, in our staging directory, we create one directory per source.

-- This model finds all cases where a model is NOT in the appropriate subdirectory:
    -- For staging models: The files should be in nested in the staging folder in a subfolder that matches their source parent's name.
    -- For non-staging models: The files should be nested closest to their appropriate folder.  

with all_graph_resources as (
    select 
        resource_name,
        resource_type,
        model_type,
        file_path,
        source_name,
        {{ dbt_utils.replace("file_path", "resource_name" ~ " || '.sql'", "''") }} as current_directory_path,
        regexp_replace(file_path,'.*/','') as file_name
    from {{ ref('int_all_graph_resources') }}
),

folders as (
    select * from {{ ref('stg_naming_convention_folders') }}
), 

all_dag_relationships as (
    select * from {{ ref('int_all_dag_relationships') }}
),

staging_models as (
    select  
        child,
        child_resource_type,
        child_model_type,
        child_file_path,
        parent_source_name,
        {{ dbt_utils.replace("child_file_path", "child" ~ " || '.sql'", "''") }} as child_directory_path,
        regexp_replace(child_file_path,'.*/','') as child_file_name
    from all_dag_relationships
    where parent_resource_type = 'source'
    and child_resource_type = 'model'
    and child_model_type = 'staging'
),

-- find all staging models that are NOT in their source parent's subdirectory
inappropriate_subdirectories_staging as (
    select distinct -- must do distinct to avoid duplicates when staging model has multiple paths to a given source
        child as resource_name,
        child_resource_type as resource_type,
        child_model_type as model_type,
        case
            when {{ dbt_utils.position("'models/'", "child_file_path") }} = 1
                then {{ dbt_utils.replace("child_file_path", "'models/'", "''") }}
            else child_file_path
        end as current_file_path,
        '{{ var("staging_folder_name") }}' || '/' || parent_source_name || '/' || child_file_name as change_file_path_to
    from staging_models
    where child_directory_path not like '%' || parent_source_name || '%'
),

-- find all non-staging models that are NOT nested closest to their appropriate folder
non_staging_models_folders_ranked as (
    select 
        all_graph_resources.resource_name,
        all_graph_resources.resource_type,
        all_graph_resources.model_type,
        all_graph_resources.file_path as current_file_path,
        all_graph_resources.file_name,
        {{ dbt_utils.position("folders.folder_name_value", "all_graph_resources.current_directory_path") }} as position_of_folder_name,
        row_number() over (partition by all_graph_resources.resource_name order by position_of_folder_name desc) as folder_name_rank,
        folders.model_type as model_type_map,
        folders.folder_name_value
    from all_graph_resources
    cross join folders
    where all_graph_resources.resource_type = 'model' and all_graph_resources.model_type <> 'staging'
),

non_staging_models_calc_change_file_path_to as (
    select 
        resource_name,
        max(case 
            when model_type = model_type_map then 'models' || '/.../' || folder_name_value || '/.../' || file_name
            else null 
        end) as change_file_path_to
    from non_staging_models_folders_ranked 
    group by resource_name
),

innappropriate_subdirectories_non_staging_models as (
    select 
        non_staging_models_folders_ranked.resource_name,
        non_staging_models_folders_ranked.resource_type,
        non_staging_models_folders_ranked.model_type,
        non_staging_models_folders_ranked.current_file_path,
        non_staging_models_calc_change_file_path_to.change_file_path_to
    from non_staging_models_folders_ranked 
    left join non_staging_models_calc_change_file_path_to 
    on non_staging_models_folders_ranked.resource_name = non_staging_models_calc_change_file_path_to.resource_name
    -- either appropriate folder_name is not in the current_directory_path or a inappropriate folder name is closer to the file_name
    where non_staging_models_folders_ranked.model_type = non_staging_models_folders_ranked.model_type_map 
    and (non_staging_models_folders_ranked.position_of_folder_name = 0 or non_staging_models_folders_ranked.folder_name_rank <> 1)
),

unioned as (
    select * from inappropriate_subdirectories_staging
    union all
    select * from innappropriate_subdirectories_non_staging_models
)

select * from unioned