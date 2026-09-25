with tests as (
    select t.unique_id, t.name, t.node_unique_id,
           regexp_extract(
               replace(t.properties_yml_file_path, chr(92), '/'),
               '^(.*)/[^/]+$',
               1
           ) as test_directory
    from {{ info_schema('data_tests') }} t
    where {{ evaluator_check_in_scope('t') }}
      and t.node_unique_id is not null
      and t.test_name is not null
),
models as (
    select m.unique_id, m.name,
           regexp_extract(
               replace(m.original_file_path, chr(92), '/'),
               '^(.*)/[^/]+$',
               1
           ) as model_directory
    from {{ info_schema('models') }} m
    where {{ evaluator_check_in_scope('m') }}
)
select tests.unique_id, tests.name as test_name,
       models.name as model_name,
       tests.test_directory as current_test_directory,
       models.model_directory as change_test_directory_to
from tests
join models on models.unique_id = tests.node_unique_id
where tests.test_directory != models.model_directory
