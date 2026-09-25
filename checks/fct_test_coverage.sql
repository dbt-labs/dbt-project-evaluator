with scoped_models as (
    select m.*,
           case
               when regexp_matches(m.name, '^base_') then 'base'
               when regexp_matches(m.name, '^stg_') then 'staging'
               when regexp_matches(m.name, '^int_') then 'intermediate'
               when regexp_matches(m.name, '^(fct|dim)_') then 'marts'
               when m.original_file_path like '%/base/%' then 'base'
               when m.original_file_path like '%/staging/%' then 'staging'
               when m.original_file_path like '%/intermediate/%' then 'intermediate'
               when m.original_file_path like '%/marts/%' then 'marts'
               else 'other'
           end as model_type
    from {{ info_schema('models') }} m
    where {{ evaluator_check_in_scope('m') }}
),
test_attachments as (
    select distinct t.unique_id as test_unique_id,
           t.node_unique_id as model_unique_id
    from {{ info_schema('data_tests') }} t
    where t.node_unique_id is not null

    union all

    select distinct t.unique_id as test_unique_id,
           edge.parent_unique_id as model_unique_id
    from {{ info_schema('data_tests') }} t
    join {{ info_schema('edges') }} edge
      on edge.child_unique_id = t.unique_id
    join scoped_models model
      on model.unique_id = edge.parent_unique_id
    where t.node_unique_id is null
),
model_tests as (
    select model.unique_id,
           model.model_type,
           count(distinct attachment.test_unique_id) as test_count
    from scoped_models model
    left join test_attachments attachment
      on attachment.model_unique_id = model.unique_id
    group by model.unique_id, model.model_type
),
coverage as (
    select count(*) as total_models,
           count(*) filter (where test_count > 0) as tested_models,
           sum(test_count) as total_tests,
           round(
               count(*) filter (where test_count > 0 and model_type = 'staging')
               * 100.0 / nullif(count(*) filter (where model_type = 'staging'), 0),
               2
           ) as staging_test_coverage_pct,
           round(
               count(*) filter (where test_count > 0 and model_type = 'intermediate')
               * 100.0 / nullif(count(*) filter (where model_type = 'intermediate'), 0),
               2
           ) as intermediate_test_coverage_pct,
           round(
               count(*) filter (where test_count > 0 and model_type = 'marts')
               * 100.0 / nullif(count(*) filter (where model_type = 'marts'), 0),
               2
           ) as marts_test_coverage_pct,
           round(
               count(*) filter (where test_count > 0 and model_type = 'other')
               * 100.0 / nullif(count(*) filter (where model_type = 'other'), 0),
               2
           ) as other_test_coverage_pct
    from model_tests
)
select total_models, total_tests, tested_models,
       round(tested_models * 100.0 / nullif(total_models, 0), 2) as test_coverage_pct,
       staging_test_coverage_pct,
       intermediate_test_coverage_pct,
       marts_test_coverage_pct,
       other_test_coverage_pct,
       round(total_tests * 1.0 / nullif(total_models, 0), 4) as test_to_model_ratio
from coverage
where tested_models * 100.0 / nullif(total_models, 0)
      < {{ var('test_coverage_target', 100) }}
