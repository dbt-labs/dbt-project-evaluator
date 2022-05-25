
with

resources as (

    select * from {{ ref('int_all_graph_resources') }}

),

relationships as (

    select * from {{ ref('int_direct_relationships') }}

),

models_per_test as (

    select
        resource_name as test_name,
        resource_id as test_id,
        direct_parent_id as parent_model_id
    from relationships
    where resource_type = 'test'

),

model_file_paths as (

    select
        resources.resource_id as model_id,
        resources.resource_name as model_name,
        resources.file_path as model_path,
        models_per_test.test_id,
        models_per_test.parent_model_id
    from resources
    join models_per_test
    on models_per_test.parent_model_id = resources.resource_id
    where resource_type = 'model'

),

test_file_paths as (

    select
        resource_id as test_id,
        resource_name as test_name,
        file_path as test_path
    from resources
    where resource_type = 'test'

),

all_file_paths as (

    select
        test_file_paths.test_id,
        test_file_paths.test_name,
        test_file_paths.test_path,
        model_file_paths.model_id,
        model_file_paths.model_name,
        model_file_paths.model_path,
        regexp_replace(test_path,'.*/','') as test_yml_name,
        {{ dbt_utils.replace("model_path", "model_name" ~ " || '.sql'", "''") }} as model_directory_path
    from model_file_paths
    join test_file_paths
    on model_file_paths.test_id = test_file_paths.test_id

),

add_path_fields as (

    select
        *,
        {{ dbt_utils.replace("test_path", "test_yml_name", "''") }} as test_yml_directory_path
    from all_file_paths

),

different_directories as (

    select
        test_name,
        model_name,
        test_yml_directory_path as current_test_directory,
        model_directory_path as change_test_directory_to
    from add_path_fields
    where model_directory_path != test_yml_directory_path

)

select * from different_directories
