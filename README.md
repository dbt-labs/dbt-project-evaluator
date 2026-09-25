# dbt_project_evaluator

This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices.
Specifically, it checks:

1. __[Modeling](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/modeling/)__ - your dbt DAG for modeling best practices
2. __[Testing](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/testing)__ - your models for testing best practices
3. __[Documentation](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/documentation)__ - your models for documentation best practices
4. __[Structure](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/structure)__ - your dbt project for file structure and naming best practices
5. __[Performance](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/performance)__ - your model materializations for performance best practices
6. __[Governance](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/governance)__ - your best practices for model governance features.

Version 2 implements these rules as native [dbt checks](https://docs.getdbt.com/docs/build/checks):
SQL queries over the dbt Information Schema that run locally at parse time. There are no warehouse
models to build, and every adapter supported by dbt v2 works. dbt Core users should stay on
[1.x](https://github.com/dbt-labs/dbt-project-evaluator/tree/v1.4.0).

Each check is a DuckDB SQL query over the Information Schema (`{{ info_schema('models') }}`,
`edges`, …) that returns one row per violation. Every 1.x rule is covered except
`fct_hard_coded_references` (see the caveat below).

## Install

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_project_evaluator
    version: [">=2.0.0", "<3.0.0"]
```

Once the package is installed, its checks run on every `dbt build` before anything compiles. You
can also run them on demand with `dbt check`. All rules are **advisory by default**
(`severity: warn`).

## Configure

Override severity or `enabled` per folder or per check from your root `dbt_project.yml`:

```yaml
checks:
  dbt_project_evaluator:
    structure:              # a whole category
      +severity: error      # block `dbt build` on violations
    documentation:
      fct_undocumented_models:
        +enabled: false     # a single rule
```

Thresholds and conventions use the same vars as 1.x: `models_fanout_threshold`,
`too_many_joins_threshold`, `chained_views_threshold`, `documentation_coverage_target`,
`test_coverage_target`, `primary_key_test_macros`, `enforced_primary_key_node_types`,
`model_types`, `<model_type>_prefixes`, `<model_type>_folder_name`, `exclude_packages` and
`exclude_paths_from_project`.

## Run

```shell
dbt check                                  # every check
dbt check fct_root_models                  # one check
dbt check --select staging                 # only report violations on selected resources
dbt ls --resource-type check --select tag:modeling
```

Each check returns the resource to fix as `unique_id`, so `--select` scopes its rows.
`fct_documentation_coverage` and `fct_test_coverage` are project-wide metrics
(`selection_filter_on: none`) and always evaluate the whole project.

## Rules

| Folder / tag | Checks |
|---|---|
| `modeling` | `fct_direct_join_to_source`, `fct_duplicate_sources`, `fct_marts_or_intermediate_dependent_on_source`, `fct_model_fanout`, `fct_multiple_sources_joined`, `fct_rejoining_of_upstream_concepts`, `fct_root_models`, `fct_source_fanout`, `fct_staging_dependent_on_marts_or_intermediate`, `fct_staging_dependent_on_staging`, `fct_too_many_joins`, `fct_unused_sources` |
| `documentation` | `fct_documentation_coverage`, `fct_undocumented_models`, `fct_undocumented_source_tables`, `fct_undocumented_sources` |
| `governance` | `fct_exposures_dependent_on_private_models`, `fct_public_models_without_contract`, `fct_undocumented_public_models` |
| `performance` | `fct_chained_views_dependencies`, `fct_exposure_parents_materializations` |
| `structure` | `fct_model_directories`, `fct_model_naming_conventions`, `fct_source_directories`, `fct_test_directories` |
| `testing` | `fct_missing_primary_key_tests`, `fct_sources_without_freshness`, `fct_test_coverage` |

Checks build on three shared relations in `macros/checks/`: `evaluator_models()` (in-scope models
typed by the naming-convention vars), `evaluator_sources()` and `evaluator_edges()` (DAG edges
with both ends' names, types and materializations).

## Caveat: hard-coded references are no longer covered by this package

1.x's `fct_hard_coded_references` is **not** part of v2. It needs each model's SQL text, and the
check-time `models` view doesn't include `raw_code`, even after `dbt compile --generate-info-schema`.
(The full information schema has the column, so `dbt show` can read it, but checks can't.)

The closest replacement is the `dbt lint` rule
[`DBT05`](https://docs.getdbt.com/reference/commands/lint#dbt-specific-rules)
(`dbt.hard_coded_reference`). It's off by default, and only your project can turn it on, in your
own `.sqlfluff`:

```ini
[sqlfluff]
templater = dbt
dialect = snowflake   # your dialect
rules = DBT05
```

DBT05 doesn't match 1.x exactly. Tested with dbt 2.0.6:

| Pattern | 1.x `fct_hard_coded_references` | `dbt lint` DBT05 |
|---|---|---|
| `from my_schema.my_table` | flagged | flagged |
| `from my_db.my_schema.my_table` | flagged | flagged |
| `from "my_db"."my_schema"."my_table"` | flagged | flagged |
| `from {{ var('orders_table') }}` | flagged | **not flagged** |

The last row matters most. Using a var to hold a table name is a common way to dodge
`ref()`/`source()`, and dbt lint renders the var to its value without treating it as hard-coded.
Also note that `dbt lint` exits 0 when it finds violations.

## Differences from 1.x

- `fct_hard_coded_references` has been removed; the `dbt lint` rule `DBT05` partly covers it (see the caveat above).
- The `dbt_project_evaluator_exceptions` seed isn't supported, because checks can't read seeds.
  Use `exclude_paths_from_project`, disable a rule, or keep it at `warn`.
- `fct_missing_primary_key_tests` doesn't count column `not_null` constraints, because constraints
  aren't in the check-time information schema.
- The warehouse models are gone, including `int_all_dag_relationships`. To query your DAG, use the
  Information Schema directly, e.g. `dbt show --inline "select * from {{ info_schema('edges') }}"`.
- The `print_dbt_project_evaluator_issues` on-run-end hook is gone. `dbt check` and `dbt build`
  report violations themselves.
- `fct_test_directories` compares a tested model's properties YAML directory with the model's
  directory. The per-test YAML path isn't populated at parse time.

## Documentation

The full rule descriptions are on [the documentation site](https://dbt-labs.github.io/dbt-project-evaluator/).
