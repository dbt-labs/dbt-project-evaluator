{#
    Exceptions: violations of a check that the project accepts. They are declared as a mapping from
    a check name to a list of patterns, e.g.

        fct_model_naming_conventions:
          - stg_legacy_%
        fct_root_models:
          - rpt_manual_%

    A violation is dropped when the name of the resource it points at (`stg_legacy_x`,
    `source_name.table`, `model.package.stg_legacy_x`...) matches a pattern, using SQL LIKE.

    The mapping comes from `dbt_project_evaluator_exceptions()`, which is dispatched so that a project
    can override it by defining `default__dbt_project_evaluator_exceptions()` in its own macros. The
    default reads the var `dbt_project_evaluator_exceptions`.
#}

{% macro dbt_project_evaluator_exceptions() -%}
    {{ return(adapter.dispatch('dbt_project_evaluator_exceptions', 'dbt_project_evaluator')()) }}
{%- endmacro %}

{% macro default__dbt_project_evaluator_exceptions() -%}
    {{ return(var('dbt_project_evaluator_exceptions', {})) }}
{%- endmacro %}


{# every check of the package: exceptions for any other name are rejected (tests keep it in sync with checks/) #}
{% macro evaluator_check_names() -%}
    {{ return([
        'fct_chained_views_dependencies',
        'fct_direct_join_to_source',
        'fct_duplicate_sources',
        'fct_exposure_parents_materializations',
        'fct_exposures_dependent_on_private_models',
        'fct_marts_or_intermediate_dependent_on_source',
        'fct_missing_primary_key_tests',
        'fct_model_directories',
        'fct_model_fanout',
        'fct_model_naming_conventions',
        'fct_multiple_sources_joined',
        'fct_public_models_without_contract',
        'fct_rejoining_of_upstream_concepts',
        'fct_root_models',
        'fct_source_directories',
        'fct_source_fanout',
        'fct_sources_without_freshness',
        'fct_staging_dependent_on_marts_or_intermediate',
        'fct_staging_dependent_on_staging',
        'fct_test_directories',
        'fct_too_many_joins',
        'fct_undocumented_models',
        'fct_undocumented_public_models',
        'fct_undocumented_source_tables',
        'fct_undocumented_sources',
        'fct_unused_sources',
    ]) }}
{%- endmacro %}


{#
    Wraps the query of a check (one row per violation, with a `unique_id` column) so that the
    violations matching an exception of `check_name` are dropped.
#}
{% macro evaluator_exceptions(check_name, query) -%}
    {%- set exception_map = dbt_project_evaluator_exceptions() or {} -%}
    {%- set known_checks = evaluator_check_names() -%}
    {%- for name in exception_map if name not in known_checks %}
        {{ exceptions.raise_compiler_error(
            "dbt_project_evaluator_exceptions: '" ~ name ~ "' is not a check of dbt_project_evaluator. Known checks: "
            ~ known_checks | join(', ')
        ) }}
    {%- endfor %}
    {%- set patterns = exception_map.get(check_name) or [] -%}
    {%- if patterns is string %}{% set patterns = [patterns] %}{% endif -%}
    {%- if patterns | length == 0 -%}
        {{ query }}
    {%- else -%}
        select *
        from (
            {{ query }}
        ) violation
        where not exists (
            select 1
            from (values {% for pattern in patterns %}('{{ pattern | string | replace("'", "''") }}'){% if not loop.last %}, {% endif %}{% endfor %}) exception(pattern)
            where violation.unique_id like exception.pattern
               or regexp_replace(violation.unique_id, '^[^.]+\.[^.]+\.', '') like exception.pattern
        )
    {%- endif -%}
{%- endmacro %}
