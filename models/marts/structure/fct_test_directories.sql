
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
    and is_primary_test_relationship

),

model_file_paths as (

    select
        resources.resource_id as model_id,
        resources.resource_name as model_name,
        resources.directory_path as model_directory_path,
        models_per_test.test_id,
        models_per_test.parent_model_id
    from resources
    inner join models_per_test
    on models_per_test.parent_model_id = resources.resource_id
    where resource_type = 'model'

),

test_file_paths as (

    select
        resource_id as test_id,
        resource_name as test_name,
        file_name as test_yml_name,
        directory_path as test_yml_directory_path
    from resources
    where resource_type = 'test'

),

all_file_paths as (

    select
        test_file_paths.test_id,
        test_file_paths.test_name,
        test_file_paths.test_yml_directory_path,
        test_file_paths.test_yml_name,
        model_file_paths.model_id,
        model_file_paths.model_name,
        model_file_paths.model_directory_path
    from model_file_paths
    inner join test_file_paths
    on model_file_paths.test_id = test_file_paths.test_id

),

different_directories as (

    select
        test_name,
        model_name,
        test_yml_directory_path as current_test_directory,
        model_directory_path as change_test_directory_to
    from all_file_paths
    where model_directory_path != test_yml_directory_path

)

select * from different_directories

{{ filter_exceptions(this) }}