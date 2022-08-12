-- This model finds all cases where a model is NOT in the appropriate subdirectory:
    -- For staging models: The files should be in nested in the staging folder in a subfolder that matches their source parent's name.
    -- For non-staging models: The files should be nested closest to their appropriate folder.  

with all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
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
        child_directory_path,
        child_file_name,
        parent_source_name
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
        child_file_path as current_file_path,
        'models/' || '{{ var("staging_folder_name") }}' || '/' || parent_source_name || '/' || child_file_name as change_file_path_to
    from staging_models
    where child_directory_path not like '%' || parent_source_name || '%'
),

-- find all non-staging models that are NOT nested closest to their appropriate folder
innappropriate_subdirectories_non_staging_models as (
    select 
        all_graph_resources.resource_name,
        all_graph_resources.resource_type,
        all_graph_resources.model_type,
        all_graph_resources.file_path as current_file_path,
        'models' || '/.../' || folders.folder_name_value || '/.../' || all_graph_resources.file_name as change_file_path_to
    from all_graph_resources
    left join folders 
        on folders.model_type = all_graph_resources.model_type 
    -- either appropriate folder_name is not in the current_directory_path or a inappropriate folder name is closer to the file_name
    where all_graph_resources.model_type <> all_graph_resources.model_type_folder 
),

unioned as (
    select * from inappropriate_subdirectories_staging
    union all
    select * from innappropriate_subdirectories_non_staging_models
)

select * from unioned

{{ filter_exceptions(this) }}