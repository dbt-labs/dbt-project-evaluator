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
`edges`, …) that returns one row per violation. Every 1.x rule is covered, and hard-coded
references are reported by [`dbt lint`](#hard-coded-references).

## Why version 2?

- **Native.** The rules are dbt checks, not models: you run them with `dbt check`, list them with `dbt ls --resource-type check`, and configure their severity, tags or whether they run in `dbt_project.yml`, as for any other resource.
- **Checked before every build.** Checks run before anything compiles on `dbt build`, so a rule set to `severity: error` stops a build that breaks it, instead of reporting after the fact.
- **Fast.** Nothing is built and nothing is read in your warehouse. On a project of about 1,900 models, all the checks take about 15 seconds, parsing included, against about 2 minutes for the version 1 `dbt build` on Snowflake.
- **Selectable.** `dbt check --select` and `state:modified` only report the violations on the resources you changed, which is what a pull request needs. Version 1 always evaluated the whole project.
- **No warehouse needed.** No credentials, no compute cost, the same result for every adapter, and CI that doesn't need secrets.
- **Smaller and easier to extend.** There is no dependency and no per-adapter code. A check is a short SQL query (6 lines for the median) over the same information schema that you can query yourself, so you can [write your own](https://dbt-labs.github.io/dbt-project-evaluator/latest/querying-the-dag/) next to the package's.

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

## Exceptions

To accept some violations of a check without disabling it, map the name of the check to a list of
entries in the var `dbt_project_evaluator_exceptions`. An entry is either a SQL `LIKE` pattern, compared
with the name (`stg_legacy_x`, `source_name.table_name`, `name.v2`) or the `unique_id` of the resource
that a row of the check points at, or a mapping from columns of the check to patterns, for example to
accept a given parent or a given pair. All the keys of a mapping must match, and a column that holds a
list matches when any of its elements does:

```yaml
vars:
  dbt_project_evaluator_exceptions:
    fct_multiple_sources_joined:
      - stg_%_unioned
    fct_unused_sources:
      - raw_shop.unused_table
    fct_staging_dependent_on_staging:
      - {name: stg_model_4, parent: stg_model_2}   # this pair only
    fct_direct_join_to_source:
      - source_parents: raw_shop.orders            # any model that reads from this source
```

For long lists, define `default__dbt_project_evaluator_exceptions()` in your own macros and return
`fromyaml(...)` of a YAML string, which allows comments. A name that isn't a check of the package is a
compile error. See [Configuring exceptions](https://dbt-labs.github.io/dbt-project-evaluator/latest/customization/exceptions/).

Coming from version 1? `python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py` converts your exceptions seed, see
[Migrating from version 1](https://dbt-labs.github.io/dbt-project-evaluator/latest/migrating-to-v2/).

## Run

```shell
dbt check                                  # every check
dbt check fct_root_models                  # one check
dbt check --select staging                 # only report violations on selected resources
dbt check --select state:modified --state path/to/main/target   # only what the pull request changes
dbt ls --resource-type check --select tag:modeling
```

Each check returns the resource to fix as `unique_id`, so `--select` scopes its rows.
`fct_documentation_coverage` and `fct_test_coverage` are project-wide metrics
(`selection_filter_on: none`) and always evaluate the whole project.

`--state` points to the artifacts of your main branch. It is not needed in a dbt platform CI job:
the state of the production environment is provided to the job through deferral.

Limitation (dbt 2.0.6, [dbt-labs/dbt#16554](https://github.com/dbt-labs/dbt/issues/16554)): `dbt check --select`
cannot scope source rows, so the checks that report sources (`fct_unused_sources`,
`fct_sources_without_freshness`, `fct_undocumented_source_tables`, `fct_undocumented_sources`,
`fct_duplicate_sources`, `fct_source_directories`, `fct_source_fanout`) report nothing when you pass a
selector, and `state:modified` does not pick up a changed source. Run them without `--select` to see
source violations.

## Skills

The package ships two agent skills (the AgentSkills format) that teach a coding agent (Claude Code, Cursor, Codex...) how to work with it:

- `using-dbt-project-evaluator`: run `dbt check`, read and fix violations, check only changed resources, set severity, thresholds, exclusions and exceptions, and use the checks in CI.
- `migrating-dbt-project-evaluator-to-v2`: migrate a project from version 1, with the migration script, the exceptions seed and the CI.

To install them, tell dbt which agent you use in `dbt_project.yml`, then run `dbt deps`:

```yaml
flags:
  ai_provider: claude      # or cursor, codex, openai, gemini, wizard; a list is accepted
```

dbt copies the skills into `.claude/skills/` (Claude Code) or `.agents/skills/` (the other agents), and updates them on every `dbt deps`. Without `ai_provider`, `dbt deps` warns and installs nothing. To turn them off, set `skills: dbt_project_evaluator: +enabled: false` (or the name of one skill under `dbt_project_evaluator:`) and run `dbt deps` again. See [the skills page](https://dbt-labs.github.io/dbt-project-evaluator/latest/skills/).

## Rules

| Folder / tag | Checks |
|---|---|
| `modeling` | `fct_direct_join_to_source`, `fct_duplicate_sources`, `fct_marts_or_intermediate_dependent_on_source`, `fct_model_fanout`, `fct_multiple_sources_joined`, `fct_rejoining_of_upstream_concepts`, `fct_root_models`, `fct_source_fanout`, `fct_staging_dependent_on_marts_or_intermediate`, `fct_staging_dependent_on_staging`, `fct_too_many_joins`, `fct_unused_sources` |
| `documentation` | `fct_documentation_coverage`, `fct_undocumented_models`, `fct_undocumented_source_tables`, `fct_undocumented_sources` |
| `governance` | `fct_exposures_dependent_on_private_models`, `fct_public_models_without_contract`, `fct_undocumented_public_models` |
| `performance` | `fct_chained_views_dependencies`, `fct_exposure_parents_materializations` |
| `structure` | `fct_model_directories`, `fct_model_naming_conventions`, `fct_source_directories`, `fct_test_directories` |
| `testing` | `fct_missing_primary_key_tests`, `fct_sources_without_freshness`, `fct_test_coverage` |

## Hard-coded references

1.x's `fct_hard_coded_references` is now covered by `dbt lint`: turn on the rule
[`DBT05`](https://docs.getdbt.com/reference/commands/lint#dbt-specific-rules) in your `.sqlfluff`:

```ini
[sqlfluff]
templater = dbt
dialect = snowflake   # your dialect
rules = DBT05
```

## Differences from 1.x

### Major changes

- **dbt >= 2.0.0 only.** dbt Core users stay on 1.x.
- **Nothing is built in the warehouse.** The checks run locally on the metadata of your project, so
  they work with every adapter, don't materialize anything and don't need `dbt_utils`. The 1.x
  `models:`, `seeds:` and `dispatch:` configuration of the package is deleted.
- **You can check selected resources only.** `dbt check --select …`, including `state:modified`, only
  reports the violations on the selected resources. In 1.x the whole project was always evaluated.
  The two coverage checks stay project-wide.
- **Severity is set with `checks:`** in `dbt_project.yml` (per category or per check) instead of the tests
  severity and the `DBT_PROJECT_EVALUATOR_SEVERITY` environment variable. The checks run before
  `dbt build`, or on demand with `dbt check`, and report the violations themselves: the
  `print_dbt_project_evaluator_issues` on-run-end hook is gone.
- **Exceptions are a var or a macro.** The `dbt_project_evaluator_exceptions` seed is replaced by the var
  (or macro) of the same name, because checks can't read seeds. It can also filter on a column of the
  check, for example a parent or a pair. See [Exceptions](#exceptions) and the
  [migration guide](https://dbt-labs.github.io/dbt-project-evaluator/latest/migrating-to-v2/), whose
  script converts the seed.
- **Hard-coded references** are reported by `dbt lint`, see [above](#hard-coded-references).
- **The DAG tables are gone**, including `int_all_dag_relationships`. To query your DAG, use the
  information schema, e.g. `dbt show --inline "select * from {{ info_schema('edges') }}"`.

### Minor changes

These don't change what is reported.

- `fct_missing_primary_key_tests` doesn't count column `not_null` constraints yet. This is a short-term
  limitation: constraints are not available to checks
  ([dbt-labs/dbt#16553](https://github.com/dbt-labs/dbt/issues/16553)).
- `exclude_paths_from_project` is a case-sensitive substring match (SQL `LIKE '%…%'`) rather than a
  regular expression, and it applies to the resources of all packages. `exclude_packages` works as in 1.x,
  including `['all']`, and never excludes your own project.
- Disabled resources (models, sources, seeds, snapshots and tests) are ignored by all the checks.
- Sources are identified by their `unique_id`: two sources with the same name in different packages
  are two resources.
- `fct_direct_join_to_source`, `fct_multiple_sources_joined`, `fct_model_fanout` and `fct_source_fanout`
  return the names of the parents or children in a list column, not their number. A pattern on such a
  column matches when any element does and accepts the whole row.
- `fct_undocumented_sources` and `fct_duplicate_sources` return one row per source.
- `fct_documentation_coverage` and `fct_test_coverage` only return a row when the coverage is below the
  target, and ignore exceptions.
- `fct_test_directories` compares a tested model's properties YAML directory with the model's
  directory. The per-test YAML path isn't populated at parse time.
- The variables `insert_batch_size`, `max_depth_dag`, `comment_chars`, `token_costs` and
  `use_native_agate_printing` are gone.

## Documentation

The full rule descriptions, the configuration options and how to run the checks in CI are on [the documentation site](https://dbt-labs.github.io/dbt-project-evaluator/).
