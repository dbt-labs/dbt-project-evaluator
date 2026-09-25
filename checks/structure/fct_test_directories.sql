-- tested models whose properties YAML (where their tests are defined) lives outside the model directory
select unique_id,
       name as model_name,
       properties_yml_file_path as current_properties_yml_file_path,
       directory_path as change_properties_yml_directory_to
from {{ evaluator_models() }}
where unique_id in (select node_unique_id from {{ info_schema('data_tests') }})
  and {{ evaluator_directory('properties_yml_file_path') }} != directory_path
