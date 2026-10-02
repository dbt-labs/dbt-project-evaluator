---
name: migrating-dbt-project-evaluator-to-v2
description: Use when a dbt project uses dbt_project_evaluator version 1 (the fct_* models and the dbt_project_evaluator_exceptions seed) and must move to version 2 (native dbt checks, dbt 2.0.0 or later), for example "migrate the project evaluator to v2", "upgrade dbt_project_evaluator", "convert the exceptions seed", "the evaluator on-run-end hook fails" or "replace dbt build --select package:dbt_project_evaluator". Do not use for a project already on version 2 (use using-dbt-project-evaluator).
---

# Migrating dbt_project_evaluator from version 1 to version 2

Version 2 replaces the warehouse models, the seed and the `on-run-end` printer with native dbt checks. Most of the work is deleting configuration. The helper script `dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py` is optional: it lists leftovers (`--check-only`) and converts the exceptions seed.

Work in small steps, show the user what changed after each one, and never drop an exception silently.

## 0. Check it applies

- `dbt --version` must be 2.0.0 or later. On dbt v1 (1.x), stop: pin `version: [">=1.0.0", "<2.0.0"]` and tell the user.
- Find the package: `packages.yml` / `dependencies.yml` with `dbt-labs/dbt_project_evaluator`, and note the current version.
- Read the root `dbt_project.yml` (vars, `models:`, `seeds:`, `tests:`, `dispatch:`, `on-run-end`), any `seeds/**/dbt_project_evaluator_exceptions.csv`, `selectors.yml`, and the CI files (`.github`, `.gitlab-ci.yml`, `Makefile`, job definitions) before changing anything.

## 1. Update the package

Set `version: [">=2.0.0", "<3.0.0"]` and run `dbt deps` (the project does not need to parse yet). Remove `dbt_utils` from `packages.yml` only if nothing else in the project uses it. The script is now at `dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py` (use the project's `packages-install-path` if it is not `dbt_packages`).

## 2. List what has to change

```shell
python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py --check-only
```

(`python3` or `py` or `uv run <path>` if `python` is not found.) It only reads files. Show the user the list; it is your to-do list for steps 3 to 6. If the script is missing, use the tables in [references/steps.md](references/steps.md).

## 3. Remove the version 1 configuration

Delete from `dbt_project.yml`: `models: dbt_project_evaluator:`, `seeds: dbt_project_evaluator:`, `dispatch` entries for the package, the `on-run-end` hook calling `print_dbt_project_evaluator_issues`, `tests:`/`data_tests: dbt_project_evaluator:`, and the vars `insert_batch_size`, `max_depth_dag`, `comment_chars`, `token_costs`, `use_native_agate_printing`. Replace any severity configuration with the `checks:` block (see [references/steps.md](references/steps.md)). Keep every other var: thresholds, coverage targets, `model_types`, prefixes, folder names and `exclude_*` still work.

## 4. Convert the exceptions (only if a seed exists)

```shell
python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py                  # writes macros/dbt_project_evaluator_exceptions.sql
python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py --format var     # prints a vars: snippet instead
```

Then:
1. Read the generated file with the user. Every line under `# NEEDS REVIEW` is a 1.x exception that could not be translated (a column that no longer exists, an unknown check, an empty pattern...). For each one, decide with the user: rewrite it on a column the 2.x check returns ([references/steps.md](references/steps.md) and the `using-dbt-project-evaluator` skill's `references/check-columns.md` list them), or drop it deliberately and say so.
2. `# NOT APPLICABLE` lines (`fct_hard_coded_references`, the coverage checks) are expected: no action.
3. Delete the seed file only after the generated entries are in place.

## 5. Replace the CI and the queries

- `dbt build --select package:dbt_project_evaluator` becomes `dbt check` (the checks also run first in `dbt build`); delete `--exclude package:dbt_project_evaluator` from selectors and jobs.
- `DBT_PROJECT_EVALUATOR_SEVERITY` still works if `+severity: "{{ env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn') }}"` is set under `checks: dbt_project_evaluator:`.
- To report only changed resources: `dbt check --select state:modified --state <artifacts of the base branch>` (no `--state` in a dbt platform CI job).
- Models of the project that `ref()` a removed table (`int_all_dag_relationships`, `int_all_graph_resources`, `stg_nodes`, the `fct_` models...) must query the information schema instead (`{{ info_schema('edges') }}`, `{{ info_schema('models') }}`); show the user each one, as this needs judgement.
- Hard-coded references: enable `dbt lint` rule `DBT05` in `.sqlfluff` (`rules = DBT05`).

## 6. Check the exclusions

`exclude_packages` works as before (`['all']` too; the root project is never excluded). `exclude_paths_from_project` values are now literal, case-sensitive substrings applied to every package: rewrite regular expressions such as `^models/legacy/.*` to `models/legacy/`.

## 7. Verify

1. `dbt parse`, then `dbt check`. Compare the violations with what the user expects; each accepted exception must have removed its violation and nothing else.
2. Re-run the checklist from step 2 until it reports nothing.
3. Summarize: files changed, exceptions translated, lines still needing a decision.

## Known limitations to tell the user about

- `fct_missing_primary_key_tests` does not count `not_null` column constraints yet (https://github.com/dbt-labs/dbt/issues/16553): a model with a `not_null` constraint plus a `unique` test is still reported.
- `dbt check --select` cannot scope the checks that report sources, and `state:modified` does not see a changed source (https://github.com/dbt-labs/dbt/issues/16554): run those checks without a selector.
- `fct_hard_coded_references` is not a check any more (see step 5).
- A 1.x pattern on a list-like column (`source_parents`, `leaf_children`, `model_children`) used to match a string such as `a, b`; it now matches each element.

Detailed tables, the exceptions column translation and the version 1 / version 2 mapping: [references/steps.md](references/steps.md).
