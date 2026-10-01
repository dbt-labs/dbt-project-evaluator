# Migrating from version 1 to version 2

Version 2 is a rewrite: the rules are native [dbt checks](https://docs.getdbt.com/docs/build/checks) that run on the information schema of your project, and the package no longer builds anything in your warehouse. Most of the work is deleting configuration that only existed for version 1.

!!! info "Who this is for"

    Version 2 needs **dbt 2.0.0 or later**. On dbt Core 1.x, stay on version 1 and pin it:

    ```yaml title="packages.yml"
    packages:
      - package: dbt-labs/dbt_project_evaluator
        version: [">=1.0.0", "<2.0.0"]
    ```

A script finds most of what has to change and converts the exceptions seed:

```shell
python3 scripts/migrate_to_v2.py --check-only   # list what to change, writes nothing
python3 scripts/migrate_to_v2.py                # also converts the exceptions seed into a macro
```

It is a single Python 3 file with no dependency. Copy [`scripts/migrate_to_v2.py`](https://github.com/dbt-labs/dbt-project-evaluator/blob/main/scripts/migrate_to_v2.py) next to your project (or run it from `dbt_packages/dbt_project_evaluator/scripts/` once version 2 is installed) and run it from the root of your project, or pass `--project-dir`. The sections below explain each step.

## 1. Update the package

```yaml title="packages.yml"
packages:
  - package: dbt-labs/dbt_project_evaluator
    version: [">=2.0.0", "<3.0.0"]
```

The package has no dependency any more: if `dbt_utils` is only in your `packages.yml` for this package, you can remove it. Then run `dbt deps`.

## 2. Remove the version 1 configuration

Delete the following from your `dbt_project.yml`. The script reports each one with its line number.

| Version 1 | What to do |
| --------- | ---------- |
| `models: dbt_project_evaluator:` (materializations, `+enabled`...) | Delete. There are no models any more. |
| `seeds: dbt_project_evaluator:` (for example disabling `dbt_project_evaluator_exceptions`) | Delete. See [exceptions](#3-convert-the-exceptions). |
| `dispatch:` entries mentioning `dbt_project_evaluator` | Delete. The cross-database macros are gone. |
| `on-run-end:` calling `print_dbt_project_evaluator_issues` | Delete. `dbt check` and `dbt build` print the violations. |
| `tests:` / `data_tests: dbt_project_evaluator:` (severity) | Replace with the `checks:` configuration below. |
| `DBT_PROJECT_EVALUATOR_SEVERITY` environment variable | Replace with the `checks:` configuration below. |
| Variables `insert_batch_size`, `max_depth_dag`, `comment_chars`, `token_costs`, `use_native_agate_printing` | Delete. |

Severity is configured per category or per check, and checks only warn by default:

```yaml title="dbt_project.yml"
checks:
  dbt_project_evaluator:
    structure:
      +severity: error          # a whole category: modeling, documentation, governance, performance, structure, testing
    documentation:
      fct_undocumented_models:
        +severity: error        # a single check
```

All the other variables (`models_fanout_threshold`, `documentation_coverage_target`, `model_types`, the prefixes and folder names...) keep working, see [overriding variables](customization/overriding-variables.md).

## 3. Convert the exceptions

The seed `dbt_project_evaluator_exceptions.csv` cannot be used any more, because checks cannot read seeds. Exceptions are now a mapping from the name of a check to a list of entries, see [configuring exceptions](customization/exceptions.md). An entry is either a pattern for the resource the violation points at, or a mapping `{column: pattern}` on a column that the check returns.

The script converts your seed into a macro (or into a `vars:` snippet with `--format var`):

```shell
python3 scripts/migrate_to_v2.py                                   # writes macros/dbt_project_evaluator_exceptions.sql
python3 scripts/migrate_to_v2.py --format var                      # prints the snippet to add under `vars:`
python3 scripts/migrate_to_v2.py --exceptions-csv path/to/file.csv --output macros/my_exceptions.sql
```

The seed is found automatically in `seeds/**/dbt_project_evaluator_exceptions.csv`. The script refuses to overwrite an existing file unless you pass `--force`. Once the generated macro is in place, delete the seed file and the `seeds: dbt_project_evaluator:` configuration.

In version 1, a row of the seed excluded the rows of the `fct_` model whose `column_name` matched `id_to_exclude`. The same row is now one entry of the check. For example, these rows:

```text
fct_name,column_name,id_to_exclude,comment
fct_undocumented_models,resource_name,stg_legacy_%,renamed in Q3
fct_staging_dependent_on_staging,parent,stg_base_%,the base models are shared
fct_direct_join_to_source,parent,raw_shop.orders,
```

become:

```yaml
fct_undocumented_models:
  - 'stg_legacy_%'   # renamed in Q3
fct_staging_dependent_on_staging:
  - {parent: 'stg_base_%'}   # the base models are shared
fct_direct_join_to_source:
  - {source_parents: 'raw_shop.orders'}
  - {model_parents: 'raw_shop.orders'}
```

The column is translated as follows. Nothing is dropped silently: whatever cannot be translated is written as a `# NEEDS REVIEW` comment with the reason and the columns that the 2.x check returns.

| Version 1 `column_name` | Version 2 entry |
| ----------------------- | --------------- |
| The resource that the 2.x violation points at: `resource_name` (most checks), `child` (`fct_chained_views_dependencies`, `fct_direct_join_to_source`, `fct_multiple_sources_joined`, `fct_root_models`, `fct_staging_dependent_on_*`, `fct_marts_or_intermediate_dependent_on_source`), `parent` (`fct_model_fanout`, `fct_source_fanout`, `fct_unused_sources`), `exposure_name`, `model_name`, `parent_and_child` (`fct_rejoining_of_upstream_concepts`) | A pattern: `'stg_legacy_%'`. |
| A column that also exists in 2.x, sometimes under another name: `parent` and `child` of `fct_staging_dependent_on_*`, `fct_chained_views_dependencies` and `fct_rejoining_of_upstream_concepts`; `parent_resource_name`, `parent_resource_type`, `parent_model_materialization` and `parent_access` of the exposure checks; `model_type`, `current_file_path` and `change_file_path_to` of `fct_model_directories`; `child_model_type` of `fct_marts_or_intermediate_dependent_on_source` (`model_type`); `is_contract_enforced` (`contract_enforced`); `is_described` (`is_described_model`) | `{column: 'pattern'}` with the 2.x name of the column. |
| `parent` of `fct_direct_join_to_source` | Two entries, `{source_parents: ...}` and `{model_parents: ...}`. |
| `parent` of `fct_marts_or_intermediate_dependent_on_source` | `{source_name: ...}`. |
| `source_parents`, `leaf_children`, `model_children` | `{column: ...}`, see the note on lists below. |
| `source_name` of `fct_undocumented_sources` | `{source_name: ...}`: the check reports one row per source. |
| `source_names` of `fct_duplicate_sources` | `{source_name: ...}`, with a note: see below. |
| A column that no longer exists (`distance`, `path`, `prefix`, `is_loop_independent`, `file_path`, `join_count`, `test_name`, `current_test_directory`, `source_db_location`, `is_public`, the `*_resource_type` and `*_model_type` columns that are now always the same, and so on) | `# NEEDS REVIEW`, with the reason. |
| `fct_hard_coded_references` | `# NOT APPLICABLE`: the rule no longer exists. |
| `fct_documentation_coverage`, `fct_test_coverage` | `# NOT APPLICABLE`: coverage checks never supported exceptions. Use `documentation_coverage_target` and `test_coverage_target`. |
| A name that is not a version 2 check, a column that is not a column of this model, an empty pattern, a pattern containing Jinja delimiters or a line break | `# NEEDS REVIEW`. |

Things that behave differently from version 1:

- **Lists.** In version 1, `source_parents`, `leaf_children` and `model_children` were strings such as `a, b`, and the pattern was compared with the whole string. They are now lists of names and the pattern is compared with **each element**: the violation is accepted when any element matches. A pattern that relied on the separator (`a, b`) no longer matches.
- **One row per child.** `fct_direct_join_to_source` had one row per parent. It now has one row per child, so accepting a parent accepts the whole violation of the child, even when it has other parents. To accept a single pair, combine two columns in the same entry: `{name: int_model_4, source_parents: raw_shop.orders}`.
- **Duplicate sources.** `fct_duplicate_sources` had one row per group of sources pointing at the same table, and `source_names` was the list of the group. It has now one row per source: an exception on `source_name` only accepts the sources it matches, so a group disappears only when all its sources match. `source_db_location` is not translated, because the column is now `source_relation` (lower case, unquoted).
- **Paths.** `fct_test_directories` returns the path of the properties YAML file (`current_properties_yml_file_path`) where version 1 returned its directory, so a pattern on `current_test_directory` has to be rewritten.
- **Case.** The match is case-sensitive, and an entry for a check that does not exist is a compile error instead of being ignored. Patterns keep their `LIKE` syntax (`%`, `_`).

!!! tip

    Run `dbt check` before and after: the violations you accepted must disappear, and no other one should. A line left under `NEEDS REVIEW` means a violation will be reported again until you handle it.

## 4. Hard-coded references

`fct_hard_coded_references` is not part of version 2, because the information schema available to checks has no SQL code. The nearest replacement is the `dbt lint` rule `DBT05`, with the differences described in [hard coded references](rules/modeling.md#hard-coded-references).

## 5. Update your CI

| Version 1 | Version 2 |
| --------- | --------- |
| `dbt build --select package:dbt_project_evaluator` | `dbt check` (checks also run first in `dbt build`) |
| `--exclude package:dbt_project_evaluator` in selectors and jobs | Delete: there is nothing to exclude. |
| Only keeping the results of the changed models | `dbt check --select state:modified --state <path>` |
| Failing the job with `DBT_PROJECT_EVALUATOR_SEVERITY=error` | `+severity: error` in the `checks:` configuration |

`--select` and `state:modified` cannot select the sources reported by the source checks yet ([dbt-labs/dbt#16554](https://github.com/dbt-labs/dbt/issues/16554)): run those checks without a selector. See [running in CI](ci-check.md) for a complete example.

## 6. Replace the queries on the package's tables

The tables of version 1 (`int_all_dag_relationships`, `int_all_graph_resources`, `int_direct_relationships`, `stg_nodes`, the `fct_` models...) do not exist any more. Models of yours that `ref()` them must query the information schema instead: `{{ info_schema('edges') }}`, `{{ info_schema('models') }}`... See [querying the DAG](querying-the-dag.md). The script lists the models that reference a removed table.

## 7. Check the exclusions

`exclude_paths_from_project` and `exclude_packages` still exist, with these differences:

- `exclude_paths_from_project` entries are **literal text**, matched with `LIKE '%…%'` against the file path and the `unique_id`. They are no longer case-insensitive regular expressions, so `^models/legacy/.*` has to become `models/legacy/`. They apply to resources of all packages.
- `exclude_packages: ['all']` is not supported: list the packages.

See [excluding packages and paths](customization/excluding-packages-and-paths.md).

## Checklist

- [ ] `packages.yml` pins `[">=2.0.0", "<3.0.0"]` and `dbt deps` passes
- [ ] `python3 scripts/migrate_to_v2.py --check-only` reports nothing left to change
- [ ] the exceptions macro (or var) is in place, its `NEEDS REVIEW` lines are handled, and the seed is deleted
- [ ] `dbt check` runs and reports the violations you expect
- [ ] CI uses `dbt check` and severity comes from the `checks:` configuration
