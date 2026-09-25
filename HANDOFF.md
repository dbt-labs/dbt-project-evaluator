# Handoff: dbt-project-evaluator as native dbt checks

> Temporary file for the next agent. Delete it before opening a PR.

## Goal

The user (Anders Swanson, GitHub `dataders`) wants to see a version of this package in which
**every rule is a native dbt check**. That means a `.sql` file under `checks/` that queries the dbt
Information Schema through `{{ info_schema('<table>') }}`, organised into category folders.
There would be no warehouse models, graph unpacking or seeds.

- Prior art: the user's spike PRs are
  [dbt-labs/dbt-project-evaluator#593](https://github.com/dbt-labs/dbt-project-evaluator/pull/593)
  and [#594](https://github.com/dbt-labs/dbt-project-evaluator/pull/594).
  #594 has 28 flat checks in `checks/` plus `checks/_checks.yml`, `macros/native_checks.sql` and
  an `integration_tests_native_checks/` consumer project. Fetch it with
  `git fetch origin pull/594/head:pr594`.
- Branch: `claude/focused-sagan-yjh04y`. Develop and push only there. Don't open a PR unless the
  user asks for one.

## Checks feature facts (from the GA docs the user pasted)

- A check is `checks/**/*.sql` and its name is the filename. It passes when it returns 0 rows.
  Checks are written in **DuckDB SQL** and run locally with no warehouse connection. Jinja renders
  at parse time and there is no separate compile step.
- `info_schema:\n  version: 1` goes in **`dbt_project.yml`**. This differs from the spike, which put
  it in `checks/_checks.yml`.
- Properties YAML sits next to the checks: `version: 2`, then
  `checks: [{name, description, config: {severity, enabled, selection_filter_on, tags, meta}}]`.
- **Default severity is `error`**, so every evaluator check should be set to `severity: warn`.
- `dbt build` runs all enabled checks before compiling anything. `--skip-checks` bypasses them.
  `dbt check [names…]` runs checks on demand.
- `--select` filters check **results** by the `unique_id` output column. A check that returns no
  `unique_id` column runs against the whole project. `selection_filter_on: <col>` overrides the
  column used.
- `+enabled: false` in `dbt_project.yml` disables checks silently.
- Preview a table with `dbt show --inline "select * from {{ info_schema('models') }}"`.
  Reference pages: `/reference/info-schema#columns-available-for-checks`, `/reference/check-configs`
  and `/reference/check-properties` on docs.getdbt.com. **Read these to confirm table and column
  names.** The names I used come from the spike and haven't been verified against GA:
  `models`, `sources`, `edges(parent_unique_id, child_unique_id)`, `graph_nodes`, `exposures`,
  `data_tests(node_unique_id, column_name, test_name, test_definition_package, properties_yml_file_path)`,
  `node_columns(node_unique_id, column_name, description, constraints)`, `seeds`, `snapshots`,
  `time_spines`, `groups`.

## Tooling / environment

- `pip install dbt` (2.0.6) is a stub that downloads the real wheel from `public.cdn.getdbt.com`.
  That host was blocked in my session, which is why nothing has been run through dbt yet.
  `docs.getdbt.com` was blocked as well.
- Nothing is validated yet. No SQL has been rendered or executed.

## What's done (uncommitted work is now committed on the branch)

`macros/checks/evaluator_check_helpers.sql` holds the shared, var-driven helpers:
- `evaluator_check_in_scope(alias)`: exclusion by `exclude_packages` and `exclude_paths_from_project`.
- `evaluator_model_type(alias)`: tries the prefix first, then the deepest configured folder, then
  `'other'`. This replicates `int_all_graph_resources`.
- `evaluator_prefix_model_type`, `evaluator_folder_model_type`, `evaluator_prefixes`,
  `evaluator_foldered_model_types`, `evaluator_directory`, `evaluator_file_name`,
  `evaluator_is_time_spine`, `evaluator_is_documented`.
- Main fix over the spike: 7 spike checks hardcoded `stg_`, `int_`, `fct_`/`dim_` and
  `/staging/`-style paths. Every check now uses the vars.

27 of 28 checks are written, rewritten from the spike so they use the helpers and return the
offending resource as `unique_id`:

| folder | checks |
|---|---|
| `checks/modeling/` | direct_join_to_source, duplicate_sources, marts_or_intermediate_dependent_on_source, model_fanout, multiple_sources_joined, rejoining_of_upstream_concepts, root_models, source_fanout, staging_dependent_on_marts_or_intermediate, staging_dependent_on_staging, too_many_joins, unused_sources |
| `checks/documentation/` | documentation_coverage (project-wide, no unique_id), undocumented_models, undocumented_source_tables, undocumented_sources |
| `checks/governance/` | exposures_dependent_on_private_models, public_models_without_contract, undocumented_public_models |
| `checks/performance/` | chained_views_dependencies, exposure_parents_materializations |
| `checks/structure/` | model_directories, model_naming_conventions, source_directories, test_directories |
| `checks/testing/` | missing_primary_key_tests, sources_without_freshness |

All files are prefixed `fct_`, so the check names match the legacy model names.

Deliberate semantic choices (preserve them, or flag them if GA data shows they're wrong):
- `model_fanout`: a leaf is a model with no non-test, in-scope children, as in legacy.
- `rejoining_of_upstream_concepts`: `unique_id` is the in-between model B, which is the one to refactor.
- `model_naming_conventions`: fails only when a name matches **no** configured prefix. This is
  equivalent to legacy because the prefix wins when typing a model.
- `model_directories`: a folder violation needs a non-null folder type that differs from the model
  type (legacy semantics). The staging-source check walks all upstream ancestors with a recursive
  `union`.
- `test_directories`: `unique_id` is the tested **model**, not the test.

## What's left

1. **`checks/testing/fct_test_coverage.sql`**: port it from `pr594:checks/fct_test_coverage.sql`.
   Replace the hardcoded model-type CASE with `evaluator_model_type('m')` and loop over
   `var('model_types')` for the per-type `<type>_test_coverage_pct` columns, as in
   `checks/documentation/fct_documentation_coverage.sql`. It is project-wide, so it returns no
   `unique_id`. Check it against `var('test_coverage_target')`.
2. **Properties YAML**: add one per folder, e.g. `checks/modeling/_modeling__checks.yml`, with
   `version: 2`, and for every check a `description` (take one-liners from `docs/rules/*.md`) and
   `config: {severity: warn}`. Consider `tags: [dbt_project_evaluator, <category>]`.
3. **`dbt_project.yml`**: add `info_schema:\n  version: 1` and bump the version to `2.0.0`. Keep the
   existing `vars:` block, because the checks call `var('models_fanout_threshold')` etc. **without
   defaults**. Find out whether a consuming root project also needs `info_schema.version` for
   package checks to run, and document the answer.
4. **Validate with real dbt 2.x** (the key step): build a consumer fixture, e.g.
   `integration_tests_checks/` with `packages.yml: - local: ../`, a DuckDB profile, and a handful
   of models, sources and exposures that deliberately violate each rule. Then run `dbt deps`,
   `dbt parse`, `dbt check`, and `dbt check <name> --select <model>` to confirm `unique_id`
   filtering works. The spike's parity numbers on the old `integration_tests/` fixture were
   18 models, 14 tests, 7 tested models, 38.89% coverage and a 0.7778 tests-per-model ratio.
   Fix any column-name mismatches against the GA info schema.
5. **Update `run_fusion_tests.sh`** and/or the CI (`.github/workflows/fusion.yml`) so the checks
   fixture runs.
6. **README**: add a "native checks" section covering install, `severity` overrides per check and
   per folder, running `dbt check`, `--select` behaviour, and the list of checks by folder.
7. **Not portable yet** (document these as gaps): `fct_hard_coded_references` needs parsed SQL,
   and row-level exceptions from the `dbt_project_evaluator_exceptions` seed have no replacement
   because checks can't read seeds. A possible replacement is a `var('check_exceptions')` map of
   check name to a list of resource names, applied through a helper macro. Propose it rather than
   building it silently.
8. **Legacy removal is the user's decision.** I tried to `git rm` the legacy implementation
   (`models/`, `seeds/`, `snapshots/`, `analysis/`, `tests/`, the old `macros/` except
   `macros/checks/`, `integration_tests*`, `tox.ini`, `run_test.sh`, `run_tox_tests.sh`,
   `.github/workflows/ci.yml`) and a permission check blocked it. **Don't delete them unless the
   user explicitly confirms.** Until then the checks live alongside the legacy models. The package
   is additive and Core-safe if dbt Core tolerates the `info_schema:` key in `dbt_project.yml`
   (Core ≥1.10 should only warn on unknown keys, but verify with `dbt parse` on dbt-core 1.12).
   Legacy macro names don't collide with the new `evaluator_*` helpers.

## Commit conventions

End commit messages with the attribution trailer the session provides. Don't put model names in
commits.
