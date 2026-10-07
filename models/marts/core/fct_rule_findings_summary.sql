-- this model summarizes finding counts across all evaluator rules, for use by
-- reporting/dashboarding tools (see integrations/dbt_charts). disabled by
-- default (see dbt_project.yml) since it refs every rule unconditionally;
-- opt in with `rule_findings_summary_enabled: true`.
--
-- prerequisite: every evaluator rule must be enabled. this model (and the
-- dashboard's per-rule tabs, which ref() each fct_ model directly too) assume
-- none of the 27 fct_ models below have been disabled via `+enabled: false`.
-- if you've disabled a rule, don't turn this on until you re-enable it -
-- a disabled rule's ref() here fails compilation outright, not just that
-- rule's row. See docs/customization/customization.md.
--
-- the rule list below has to be static: dbt's dependency graph isn't
-- available yet while a model's own dependencies are being inferred, so a
-- ref() keyed off `graph.nodes` introspection can't be statically resolved
-- and fails to compile.

{% set rule_categories = {
    'fct_undocumented_models': 'documentation',
    'fct_undocumented_source_tables': 'documentation',
    'fct_undocumented_sources': 'documentation',

    'fct_exposures_dependent_on_private_models': 'governance',
    'fct_public_models_without_contract': 'governance',
    'fct_undocumented_public_models': 'governance',

    'fct_direct_join_to_source': 'modeling',
    'fct_duplicate_sources': 'modeling',
    'fct_hard_coded_references': 'modeling',
    'fct_marts_or_intermediate_dependent_on_source': 'modeling',
    'fct_model_fanout': 'modeling',
    'fct_multiple_sources_joined': 'modeling',
    'fct_rejoining_of_upstream_concepts': 'modeling',
    'fct_root_models': 'modeling',
    'fct_source_fanout': 'modeling',
    'fct_staging_dependent_on_marts_or_intermediate': 'modeling',
    'fct_staging_dependent_on_staging': 'modeling',
    'fct_too_many_joins': 'modeling',
    'fct_unused_sources': 'modeling',

    'fct_chained_views_dependencies': 'performance',
    'fct_exposure_parents_materializations': 'performance',

    'fct_model_directories': 'structure',
    'fct_model_naming_conventions': 'structure',
    'fct_source_directories': 'structure',
    'fct_test_directories': 'structure',

    'fct_missing_primary_key_tests': 'testing',
    'fct_sources_without_freshness': 'testing'
} %}

with

{% for rule_name, category in rule_categories.items() %}
{{ rule_name }} as (

    select
        '{{ rule_name }}' as rule_name,
        '{{ category }}' as category,
        count(*) as finding_count

    from {{ ref(rule_name) }}

),
{% endfor %}

unioned as (
    {% for rule_name in rule_categories.keys() %}
    select * from {{ rule_name }}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

select * from unioned
