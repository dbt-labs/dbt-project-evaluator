-- project-wide: fails when the share of models with at least one test is below `test_coverage_target`.
-- A test covers the model it is declared on. Singular tests are not declared on a node, so they cover
-- every model they depend on.
with model_tests as (
    select node_unique_id as model_unique_id, unique_id as test_unique_id
    from {{ evaluator_data_tests() }}
    where node_unique_id is not null

    union all

    select edge.parent_unique_id, test.unique_id
    from {{ evaluator_data_tests() }} test
    join {{ info_schema('edges') }} edge on edge.child_unique_id = test.unique_id
    where test.node_unique_id is null and test.test_name is null
),

models as (
    select model.model_type, count(model_test.test_unique_id) as test_count
    from {{ evaluator_models() }} model
    left join model_tests model_test on model_test.model_unique_id = model.unique_id
    group by model.unique_id, model.model_type
),

totals as (
    select count(distinct model_test.test_unique_id) as distinct_tests
    from model_tests model_test
    join {{ evaluator_models() }} model on model.unique_id = model_test.model_unique_id
)

select count(*) as total_models,
       count(*) filter (where test_count > 0) as tested_models,
       any_value(distinct_tests) as total_tests,
       round(tested_models * 100.0 / nullif(total_models, 0), 2) as test_coverage_pct,
       round(total_tests * 1.0 / nullif(total_models, 0), 4) as test_to_model_ratio,
       {{ evaluator_pct_by_model_type('test_count > 0', 'test_coverage_pct') }}
from models, totals
having test_coverage_pct < {{ var('test_coverage_target') }}
