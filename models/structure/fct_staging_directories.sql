-- Because we often work with multiple data sources, in our staging directory, we create one directory per source.

-- This model finds all cases where a staging model is NOT in the appropriate subdirectory
    -- how should we define "staging" model here? 
        -- by naming convention in stg_all_graph_resource?
        -- by being in a folder called staging?
        -- or all direct children of source tables?

with staging_relationships as (
    select * from {{ ref('int_all_dag_relationships') }}
    where child_resource_type = 'model'
    and child_model_type = 'staging'
),

source_parents as (
    select  
        child,
        child_file_path,
        -- should we create a new field called source_name in stg_all_graph_resources and bring through so we don't have to do a this substring?
        left(parent, charindex('.',parent) - 1) as source,
        left(child_file_path, len(child_file_path) - charindex('/',reverse(child_file_path)) + 1) as child_directory_path
    from staging_relationships
    where parent_resource_type = 'source'
),

-- find all staging models that are NOT in their source parent's subdirectory
inappropriate_subdirectories_staging as (
    select 
        child as model,
        child_directory_path as current_directory_path,
        'models/staging/' || source || '/' as change_directory_path_to
    from source_parents
    where child_directory_path not like '%' || source || '%'
)

-- find all sources that are definied in a .yml file NOT in their subdirectory
select * from inappropriate_subdirectories_staging