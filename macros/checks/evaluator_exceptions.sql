{#
    Exceptions: violations of a check that the project accepts. They are declared as a mapping from
    a check name to a list of patterns, e.g.

        fct_model_naming_conventions:
          - stg_legacy_%                  # the resource the violation points at
        fct_staging_dependent_on_staging:
          - parent: stg_base_%            # a column of the check
          - {name: stg_a, parent: stg_b}  # several columns: all of them must match

    A string is matched with SQL LIKE against the name of the resource the violation points at
    (`stg_legacy_x`, `source_name.table`) and against its unique_id. A mapping is matched against
    columns of the check: all its keys must match, and a column that is a list matches when any of
    its elements does. A violation is dropped when any entry of its check matches.

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


{# SQL condition: the resource a violation points at matches `pattern` #}
{% macro evaluator_resource_matches(pattern) -%}
    (violation.unique_id like '{{ pattern }}' or regexp_replace(violation.unique_id, '^[^.]+\.[^.]+\.', '') like '{{ pattern }}')
{%- endmacro %}


{# SQL condition: `column` of a violation, or one of its elements when it is a list, matches `pattern` #}
{% macro evaluator_column_matches(column, pattern) -%}
    len(list_filter(coalesce(try_cast(violation."{{ column }}" as varchar[]), [cast(violation."{{ column }}" as varchar)]), element -> element like '{{ pattern }}')) > 0
{%- endmacro %}


{% macro evaluator_sql_literal(value) -%}
    {{ return(value | string | replace("'", "''")) }}
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
    {%- set entries = exception_map.get(check_name) or [] -%}
    {%- if entries is string or entries is mapping %}{% set entries = [entries] %}{% endif -%}
    {%- set conditions = [] -%}
    {%- for entry in entries -%}
        {%- if entry is mapping -%}
            {%- if entry | length == 0 -%}
                {{ exceptions.raise_compiler_error("dbt_project_evaluator_exceptions: an entry of '" ~ check_name ~ "' is an empty mapping") }}
            {%- endif -%}
            {%- set parts = [] -%}
            {%- for column, column_patterns in entry.items() -%}
                {%- if not (column | string).replace('_', '').isalnum() -%}
                    {{ exceptions.raise_compiler_error("dbt_project_evaluator_exceptions: '" ~ column ~ "' is not a valid column name (check '" ~ check_name ~ "')") }}
                {%- endif -%}
                {%- if column_patterns is none or (column_patterns is not string and column_patterns | length == 0) -%}
                    {{ exceptions.raise_compiler_error("dbt_project_evaluator_exceptions: column '" ~ column ~ "' of '" ~ check_name ~ "' needs at least one pattern") }}
                {%- endif -%}
                {%- set column_patterns = [column_patterns] if column_patterns is string else column_patterns -%}
                {%- set alternatives = [] -%}
                {%- for pattern in column_patterns -%}
                    {%- do alternatives.append(evaluator_column_matches(column, evaluator_sql_literal(pattern))) -%}
                {%- endfor -%}
                {%- do parts.append('(' ~ alternatives | join(' or ') ~ ')') -%}
            {%- endfor -%}
            {%- do conditions.append('(' ~ parts | join(' and ') ~ ')') -%}
        {%- else -%}
            {%- do conditions.append(evaluator_resource_matches(evaluator_sql_literal(entry))) -%}
        {%- endif -%}
    {%- endfor -%}
    {%- if conditions | length == 0 -%}
        {{ query }}
    {%- else -%}
        select *
        from (
            {{ query }}
        ) violation
        where not (
            {{ conditions | join('\n            or ') }}
        )
    {%- endif -%}
{%- endmacro %}
