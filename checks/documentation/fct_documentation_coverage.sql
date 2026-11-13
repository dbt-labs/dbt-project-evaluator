-- project-wide: fails when the share of documented models is below `documentation_coverage_target`
select count(*) as total_models,
       count(*) filter (where is_documented) as documented_models,
       round(documented_models * 100.0 / nullif(total_models, 0), 2) as documentation_coverage_pct,
       {{ evaluator_pct_by_model_type('is_documented', 'documentation_coverage_pct') }}
from {{ evaluator_models() }}
having documentation_coverage_pct < {{ var('documentation_coverage_target') }}
