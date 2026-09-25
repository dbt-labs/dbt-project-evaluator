-- project-wide: fails when the share of models with at least one test is below `test_coverage_target`.
-- Returns no unique_id on purpose, so it always evaluates the whole project.
with models as (
    select model.unique_id,
           {{ evaluator_model_type('model') }} as model_type
    from {{ info_schema('models') }} model
    where {{ evaluator_check_in_scope('model') }}
),

-- a test covers every model it depends on (generic tests via node_unique_id, others via edges)
test_attachments as (
    select test.unique_id as test_unique_id, test.node_unique_id as model_unique_id
    from {{ info_schema('data_tests') }} test
    where test.node_unique_id is not null

    union

    select edge.child_unique_id, edge.parent_unique_id
    from {{ info_schema('edges') }} edge
    join {{ info_schema('data_tests') }} test on test.unique_id = edge.child_unique_id
    where test.node_unique_id is null
),

model_tests as (
    select models.unique_id,
           models.model_type,
           count(distinct test_attachments.test_unique_id) as test_count
    from models
    left join test_attachments on test_attachments.model_unique_id = models.unique_id
    group by models.unique_id, models.model_type
),

coverage as (
    select count(*) as total_models,
           count(*) filter (where test_count > 0) as tested_models,
           coalesce(sum(test_count), 0) as total_tests,
           round(count(*) filter (where test_count > 0) * 100.0 / nullif(count(*), 0), 2) as test_coverage_pct,
           round(coalesce(sum(test_count), 0) * 1.0 / nullif(count(*), 0), 4) as test_to_model_ratio
           {%- for model_type in var('model_types') %},
           round(
               count(*) filter (where test_count > 0 and model_type = '{{ model_type }}') * 100.0
               / nullif(count(*) filter (where model_type = '{{ model_type }}'), 0),
               2
           ) as {{ model_type }}_test_coverage_pct
           {%- endfor %}
    from model_tests
)

select *
from coverage
where test_coverage_pct < {{ var('test_coverage_target') }}
