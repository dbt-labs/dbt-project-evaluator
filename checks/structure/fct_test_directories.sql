-- generic tests defined in a YAML file outside the directory of the model they test.
-- unique_id is the tested model, so `--select my_model` surfaces its misplaced tests.
select model.unique_id,
       model.name as model_name,
       test.name as test_name,
       {{ evaluator_directory('test.properties_yml_file_path') }} as current_test_directory,
       {{ evaluator_directory('model.original_file_path') }} as change_test_directory_to
from {{ info_schema('data_tests') }} test
join {{ info_schema('models') }} model on model.unique_id = test.node_unique_id
where {{ evaluator_check_in_scope('test') }}
  and {{ evaluator_check_in_scope('model') }}
  and test.test_name is not null
  and {{ evaluator_directory('test.properties_yml_file_path') }}
      != {{ evaluator_directory('model.original_file_path') }}
