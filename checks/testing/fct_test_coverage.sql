-- project-wide: fails when the share of models with at least one test is below `test_coverage_target`.
-- A test covers every model it depends on (via edges, which also catches singular tests).
with models as (
    select model.model_type, count(distinct edge.child_unique_id) as test_count
    from {{ evaluator_models() }} model
    left join {{ info_schema('edges') }} edge
      on edge.parent_unique_id = model.unique_id
     and edge.child_unique_id in (select unique_id from {{ info_schema('data_tests') }})
    group by model.unique_id, model.model_type
)

select count(*) as total_models,
       count(*) filter (where test_count > 0) as tested_models,
       sum(test_count) as total_tests,
       round(tested_models * 100.0 / nullif(total_models, 0), 2) as test_coverage_pct,
       round(total_tests * 1.0 / nullif(total_models, 0), 4) as test_to_model_ratio,
       {{ evaluator_pct_by_model_type('test_count > 0', 'test_coverage_pct') }}
from models
having test_coverage_pct < {{ var('test_coverage_target') }}
