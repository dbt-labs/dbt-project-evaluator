# Version 1 to version 2: reference tables

Source of truth: `dbt_packages/dbt_project_evaluator/docs/migrating-to-v2.md` (also published at https://dbt-labs.github.io/dbt-project-evaluator/latest/migrating-to-v2/).

## Configuration to remove or replace in dbt_project.yml

| Version 1 | Version 2 |
| --------- | --------- |
| `models: dbt_project_evaluator:` (materializations, `+enabled`...) | Delete: there are no models |
| `seeds: dbt_project_evaluator:` (for example disabling the exceptions seed) | Delete |
| `dispatch:` entries for `dbt_project_evaluator` | Delete |
| `on-run-end:` calling `print_dbt_project_evaluator_issues` | Delete: `dbt check` and `dbt build` print the violations |
| `tests:` / `data_tests: dbt_project_evaluator:` (severity) | `checks: dbt_project_evaluator:` (below) |
| `DBT_PROJECT_EVALUATOR_SEVERITY` env var | `+severity` in `checks:` (it can still read the env var through `env_var`) |
| vars `insert_batch_size`, `max_depth_dag`, `comment_chars`, `token_costs`, `use_native_agate_printing` | Delete |

```yaml
checks:
  dbt_project_evaluator:
    structure:
      +severity: error          # a category: modeling, documentation, governance, performance, structure, testing
    documentation:
      fct_undocumented_models:
        +severity: error        # one check
```

## Exceptions: 1.x seed row to 2.x entry

A 1.x row `(fct_name, column_name, id_to_exclude, comment)` removed the rows of the `fct_` model whose `column_name` matched the `LIKE` pattern `id_to_exclude`. In 2.x the check is a key of `dbt_project_evaluator_exceptions` and the entry is a string (the resource the violation points at) or `{column: pattern}`.

| 1.x `column_name` | 2.x entry |
| ----------------- | --------- |
| the resource the violation points at (`resource_name` for most checks; `child` for `fct_chained_views_dependencies`, `fct_direct_join_to_source`, `fct_multiple_sources_joined`, `fct_root_models`, `fct_staging_dependent_on_*`, `fct_marts_or_intermediate_dependent_on_source`; `parent` for `fct_model_fanout`, `fct_source_fanout`, `fct_unused_sources`; `exposure_name`; `model_name`; `parent_and_child`) | a plain string pattern |
| a column that still exists in 2.x (`parent`/`child` of the staging, chained views and rejoining checks, the exposure checks' `parent_*` columns, `model_type`, paths of the directory checks...) | `{column: pattern}` |
| `parent` of `fct_direct_join_to_source` | two entries: `{source_parents: p}` and `{model_parents: p}` |
| `parent` of `fct_marts_or_intermediate_dependent_on_source` | `{source_name: p}` |
| `source_parents`, `leaf_children`, `model_children` | `{column: p}` (matches any element of the list) |
| `source_name` of `fct_undocumented_sources`, `source_names` of `fct_duplicate_sources` | `{source_name: p}` (one row per source now) |
| a column that no longer exists (`distance`, `path`, `prefix`, `is_loop_independent`, `file_path`, `join_count`, `test_name`, `current_test_directory`, `source_db_location`, `is_public`...) | `# NEEDS REVIEW`: ask the user |
| `fct_hard_coded_references`; coverage checks | `# NOT APPLICABLE` |

Behaviour changes to explain when a translated exception behaves differently: `fct_direct_join_to_source` has one row per child (accepting a parent accepts the whole violation of the child; combine columns to accept one pair: `{name: int_model_4, source_parents: raw_shop.orders}`); matching is case-sensitive; an unknown check name is a compile error; versioned models are `name.v2`.

## CI

| Version 1 | Version 2 |
| --------- | --------- |
| `dbt build --select package:dbt_project_evaluator` | `dbt check` |
| `--exclude package:dbt_project_evaluator` | delete |
| keeping the results of changed models only | `dbt check --select state:modified --state <path>` |
| `DBT_PROJECT_EVALUATOR_SEVERITY=error` | `+severity: error` under `checks:` |

## Queries on removed tables

`int_all_dag_relationships`, `int_all_graph_resources`, `int_direct_relationships`, `stg_nodes` and the `fct_` models no longer exist. Use the information schema: `dbt parse --generate-info-schema`, then `dbt show --inline "select * from {{ info_schema('edges') }}"`; views include `models`, `sources`, `edges`, `node_columns`, `data_tests`, `exposures`.
