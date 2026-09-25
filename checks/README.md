# Native checks (dbt v2)

Every dbt-project-evaluator rule is a [dbt check](https://docs.getdbt.com/docs/build/checks):
a DuckDB SQL query over the dbt Information Schema (`{{ info_schema('models') }}`, `edges`, …)
that returns one row per violation. Checks run locally at parse time. They need no warehouse
connection and don't build any models.

## Install

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_project_evaluator
    version: [">=2.0.0", "<3.0.0"]
```

Once the package is installed, its checks run on every `dbt build` before anything compiles. You
can also run them on demand with `dbt check`. All rules are **advisory by default**
(`severity: warn`). v2 requires dbt v2; dbt Core users should stay on dbt_project_evaluator 1.x.

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

Shared logic, such as scoping, model-type classification from the prefix and folder vars, and
DAG node attributes, lives in `macros/checks/`.

## Hard-coded references: use `dbt lint`

1.x's `fct_hard_coded_references` now lives in [`dbt lint`](https://docs.getdbt.com/reference/commands/lint#dbt-specific-rules)
as rule `DBT05` (`dbt.hard_coded_reference`). It flags `from my_schema.my_table`-style relations
that should be a `ref()` or `source()`. It needs the SQL text, which checks can't see (the
`models` view has no `raw_code`), so it can't be written as a check.

A package can't turn on lint rules for your project. Add them to your own `.sqlfluff`:

```ini
[sqlfluff]
templater = dbt
dialect = snowflake   # your dialect
rules = DBT05         # optionally also DBT01 (import CTEs), DBT02–DBT04
```

Then run `dbt lint`. It exits 0 on violations, so like the checks it's advisory unless your CI
treats its output as blocking; `--format github-annotation` works well there. One difference
from 1.x: DBT05 doesn't flag `{{ var('...') }}` used as a table name.

## Differences from 1.x

- `fct_hard_coded_references` is replaced by the `dbt lint` rule `DBT05` (see above).
- The `dbt_project_evaluator_exceptions` seed isn't supported, because checks can't read seeds.
  Use `exclude_paths_from_project`, disable a rule, or keep it at `warn`.
- `fct_missing_primary_key_tests` doesn't count column `not_null` constraints, because constraints
  aren't in the check-time information schema.
- `fct_test_directories` compares a tested model's properties YAML directory with the model's
  directory. The per-test YAML path isn't populated at parse time.
