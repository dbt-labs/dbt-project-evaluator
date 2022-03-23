-- Because we often work with multiple data sources, in our staging directory, we create one directory per source.

-- This model finds all cases where a staging model or source definition is NOT in the appropriate subdirectory
    -- how should we define "staging" model here? 
        -- by naming convention in stg_all_graph_resource?
        -- by being in a folder called staging?
        -- or all direct children of source tables?

-- TO DO: consider also adding tests/documentation that are in the incorrect subdirectory?
-- TO DO: how to handle staging models that depend on multiple sources?

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
        -- should we create a new field called source_name in stg_all_graph_resources and bring through so we don't have to do a this substring?
        left(parent, charindex('.',parent) - 1) as source,
        left(child_file_path, len(child_file_path) - charindex('/',reverse(child_file_path)) + 1) as child_directory_path,
        right(child_file_path, charindex('/', reverse(child_file_path)) - 1) as child_file_name
    from all_dag_relationships
    where parent_resource_type = 'source'
    and child_resource_type = 'model'
    and child_model_type = 'staging'
),

sources as (
    select 
        resource_name,
        file_path,
        left(resource_name, charindex('.',resource_name) - 1) as source,
        left(file_path, len(file_path) - charindex('/',reverse(file_path)) + 1) as current_directory_path,
        right(file_path, charindex('/', reverse(file_path)) - 1) as file_name
    from all_graph_resources
    where resource_type = 'source'
),

-- find all sources that are definied in a .yml file NOT in their subdirectory
inappropriate_subdirectories_sources as (
    select 
        resource_name,
        file_path as current_file_path,
        'models/' || '{{ var("staging_folder_name") }}' || '/' || source || '/' || file_name as change_file_path_to
    from sources
    where current_directory_path not like '%' || source || '%'
),

-- find all staging models that are NOT in their source parent's subdirectory
inappropriate_subdirectories_staging as (
    select distinct -- must do distinct to avoid duplicates when staging model has multiple paths to a given source
        child as resource_name,
        child_file_path as current_file_path,
        '{{ var("staging_folder_name") }}' || '/' || source || '/' || child_file_name as change_file_path_to
    from staging_models
    where child_directory_path not like '%' || source || '%'
),

unioned as (
    select * from inappropriate_subdirectories_staging
    union all 
    select * from inappropriate_subdirectories_sources
)

select * from unioned