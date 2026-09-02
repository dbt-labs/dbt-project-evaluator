with typed_models as (
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
coverage as (
    select count(*) as total_models,
           count(*) filter (
               where nullif(trim(description), '') is not null
           ) as documented_models,
           round(
               count(*) filter (
                   where nullif(trim(description), '') is not null
                     and model_type = 'staging'
               ) * 100.0
               / nullif(count(*) filter (where model_type = 'staging'), 0),
               2
           ) as staging_documentation_coverage_pct,
           round(
               count(*) filter (
                   where nullif(trim(description), '') is not null
                     and model_type = 'intermediate'
               ) * 100.0
               / nullif(count(*) filter (where model_type = 'intermediate'), 0),
               2
           ) as intermediate_documentation_coverage_pct,
           round(
               count(*) filter (
                   where nullif(trim(description), '') is not null
                     and model_type = 'marts'
               ) * 100.0
               / nullif(count(*) filter (where model_type = 'marts'), 0),
               2
           ) as marts_documentation_coverage_pct,
           round(
               count(*) filter (
                   where nullif(trim(description), '') is not null
                     and model_type = 'other'
               ) * 100.0
               / nullif(count(*) filter (where model_type = 'other'), 0),
               2
           ) as other_documentation_coverage_pct
    from typed_models
)
select total_models, documented_models,
       round(documented_models * 100.0 / nullif(total_models, 0), 2)
       as documentation_coverage_pct,
       staging_documentation_coverage_pct,
       intermediate_documentation_coverage_pct,
       marts_documentation_coverage_pct,
       other_documentation_coverage_pct
from coverage
where documented_models * 100.0 / nullif(total_models, 0)
      < {{ var('documentation_coverage_target', 100) }}
