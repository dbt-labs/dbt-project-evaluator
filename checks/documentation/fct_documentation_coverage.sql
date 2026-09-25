-- project-wide: fails when the share of documented models is below `documentation_coverage_target`.
-- Returns no unique_id on purpose, so it always evaluates the whole project.
with models as (
    select {{ evaluator_model_type('model') }} as model_type,
           {{ evaluator_is_documented('model.description') }} as is_documented
    from {{ info_schema('models') }} model
    where {{ evaluator_check_in_scope('model') }}
),

coverage as (
    select count(*) as total_models,
           count(*) filter (where is_documented) as documented_models,
           round(count(*) filter (where is_documented) * 100.0 / nullif(count(*), 0), 2) as documentation_coverage_pct
           {%- for model_type in var('model_types') %},
           round(
               count(*) filter (where is_documented and model_type = '{{ model_type }}') * 100.0
               / nullif(count(*) filter (where model_type = '{{ model_type }}'), 0),
               2
           ) as {{ model_type }}_documentation_coverage_pct
           {%- endfor %}
    from models
)

select *
from coverage
where documentation_coverage_pct < {{ var('documentation_coverage_target') }}
