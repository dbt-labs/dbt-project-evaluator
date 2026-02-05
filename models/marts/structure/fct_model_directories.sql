-- This model finds all cases where a model is NOT in the appropriate subdirectory:
    -- For staging models: The files should be nested in the staging folder in a subfolder that matches their source parent's name.
    -- For non-staging models: The files should be nested closest to their appropriate folder.  
{{ config(materialized='table') }}

{% set directory_pattern = get_directory_pattern() %}
 
with all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where not is_excluded
),

folders as (
    select * from {{ ref('stg_naming_convention_folders') }}
), 

all_dag_relationships as (
    select * from {{ ref('int_all_dag_relationships') }}
    where not child_is_excluded
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

--Add this to get all the stage models with count of parent source. Next step will be to count which ones have more than one source parent
staging_by_parent_source_count as (
    select
        count(distinct parent_source_name) as resource_count,
        child as resource_name,
        child_resource_type as resource_type,
        child_model_type as model_type,
        child_file_path as current_file_path,
        'models{{ directory_pattern }}staging{{ directory_pattern }}' || staging_models.parent_source_name || '{{ directory_pattern }}' as list_agg_string
    from staging_models
    group by child, child_resource_type, child_model_type, child_file_path,
        'models{{ directory_pattern }}staging{{ directory_pattern }}' || staging_models.parent_source_name || '{{ directory_pattern }}'
),

--Added this CTE to listagg() the multiple suggested paths and advise the user to split the source file into those two places.
multiple_sources_staging_to_split as (
    select 
        staging_models.child as resource_name,
        staging_models.child_resource_type as resource_type,
        staging_models.child_model_type as model_type,
        staging_models.child_file_path as current_file_path,
        'More than one source. Split into separate staging models in: ' ||
        {{ dbt.listagg(measure='list_agg_string', delimiter_text="' AND '", order_by_clause='order by current_file_path'  if target.type in ['snowflake','redshift','duckdb','trino']) }} as change_file_path_to
    from staging_models
    join staging_by_parent_source_count on staging_models.child = staging_by_parent_source_count.resource_name and
                                           staging_models.child_resource_type = staging_by_parent_source_count.resource_type and
                                           staging_models.child_model_type = staging_by_parent_source_count.model_type and
                                           staging_models.child_file_path = staging_by_parent_source_count.current_file_path
    where staging_by_parent_source_count.resource_count > 1
    group by staging_models.child, staging_models.child_resource_type, staging_models.child_model_type, staging_models.child_file_path
),

-- find all staging models that are NOT in their source parent's subdirectory
inappropriate_subdirectories_staging as (
    select distinct -- must do distinct to avoid duplicates when staging model has multiple paths to a given source
        child as resource_name,
        child_resource_type as resource_type,
        child_model_type as model_type,
        child_file_path as current_file_path,
        'models{{ directory_pattern }}' || '{{ var("staging_folder_name") }}' || '{{ directory_pattern }}' || parent_source_name || '{{ directory_pattern }}' || child_file_name as change_file_path_to
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
        'models' || '{{ directory_pattern }}...{{ directory_pattern }}' || folders.folder_name_value || '{{ directory_pattern }}...{{ directory_pattern }}' || all_graph_resources.file_name as change_file_path_to
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
    union all --Added union all to append these results
    select * from multiple_sources_staging_to_split
)

select * from unioned

{{ filter_exceptions() }}
 

