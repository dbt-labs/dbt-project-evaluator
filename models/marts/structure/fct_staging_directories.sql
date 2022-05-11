-- Because we often work with multiple data sources, in our staging directory, we create one directory per source.

-- This model finds all cases where a staging model or source definition is NOT in the appropriate subdirectory
    -- how should we define "staging" model here? 
        -- by naming convention in stg_all_graph_resource?
        -- by being in a folder called staging?
        -- or all direct children of source tables?

-- TO DO: consider also adding tests/documentation that are in the incorrect subdirectory?
-- TO DO: how to handle staging models that depend on multiple sources?
-- TO DO: how to handle base models?

with all_graph_resources as (
    select * from {{ ref('stg_all_graph_resources') }}
),

all_dag_relationships as (
    select * from {{ ref('int_all_dag_relationships') }}
),

staging_models as (
    select  
        child,
        child_file_path,
        parent_source_name,
        {{ dbt_utils.replace("child_file_path", "child" ~ " || '.sql'", "''") }} as child_directory_path,
        regexp_replace(child_file_path,'.*/','') as child_file_name
    from all_dag_relationships
    where parent_resource_type = 'source'
    and child_resource_type = 'model'
    and child_model_type = 'staging'
),

sources as (
    select 
        resource_name,
        file_path,
        source_name,
        replace(file_path, resource_name || '.sql', '') as current_directory_path,
        regexp_replace(file_path,'.*/','') as file_name
    from all_graph_resources
    where resource_type = 'source'
),

-- find all sources that are definied in a .yml file NOT in their subdirectory
inappropriate_subdirectories_sources as (
    select 
        resource_name,
        file_path as current_file_path,
        'models/' || '{{ var("staging_folder_name") }}' || '/' || source_name || '/' || file_name as change_file_path_to
    from sources
    where current_directory_path not like '%' || source_name || '%'
),

-- find all staging models that are NOT in their source parent's subdirectory
inappropriate_subdirectories_staging as (
    select distinct -- must do distinct to avoid duplicates when staging model has multiple paths to a given source
        child as resource_name,
        child_file_path as current_file_path,
        '{{ var("staging_folder_name") }}' || '/' || parent_source_name || '/' || child_file_name as change_file_path_to
    from staging_models
    where child_directory_path not like '%' || parent_source_name || '%'
),

unioned as (
    select * from inappropriate_subdirectories_staging
    union all 
    select * from inappropriate_subdirectories_sources
)

select * from unioned