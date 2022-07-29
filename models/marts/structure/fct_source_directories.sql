-- Because we often work with multiple data sources, in our staging directory, we create one directory per source.

-- This model finds all cases where a source definition is NOT in the appropriate subdirectory.

with all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
),

-- find all sources that are definied in a .yml file NOT in their subdirectory
inappropriate_subdirectories_sources as (
    select 
        resource_name,
        resource_type,
        file_path as current_file_path,
        'models/' || '{{ var("staging_folder_name") }}' || '/' || source_name || '/' || file_name as change_file_path_to
    from all_graph_resources
    where resource_type = 'source'
    and directory_path not like '%' || source_name || '%'
)

select * from inappropriate_subdirectories_sources

{{ filter_exceptions(this) }}