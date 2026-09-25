-- tested models whose properties YAML (where their generic tests are defined) lives
-- outside the model's own directory
with test_counts as (
    select node_unique_id, count(*) as number_of_tests
    from {{ info_schema('data_tests') }}
    where test_name is not null
    group by node_unique_id
)

select model.unique_id,
       model.name as model_name,
       test_counts.number_of_tests,
       model.properties_yml_file_path as current_properties_yml_file_path,
       {{ evaluator_directory('model.original_file_path') }} as change_properties_yml_directory_to
from {{ info_schema('models') }} model
join test_counts on test_counts.node_unique_id = model.unique_id
where {{ evaluator_check_in_scope('model') }}
  and nullif(model.properties_yml_file_path, '') is not null
  and {{ evaluator_directory('model.properties_yml_file_path') }}
      != {{ evaluator_directory('model.original_file_path') }}
