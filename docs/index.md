# dbt_project_evaluator

This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices.
Specifically, this package checks:

1. __[Modeling](rules/modeling.md)__ - your dbt DAG for modeling best practices
2. __[Testing](rules/testing.md)__ - your models for testing best practices
3. __[Documentation](rules/documentation.md)__ - your models for documentation best practices
4. __[Structure](rules/structure.md)__ - your dbt project for file structure and naming best practices
5. __[Performance](rules/performance.md)__ - your model materializations for performance best practices
6. __[Governance](rules/governance.md)__ - your model governance feature best practices

Version 2 implements each rule as a native [dbt check](https://docs.getdbt.com/docs/build/checks): a SQL query over the dbt information schema that runs locally, at parse time. Nothing is built in your warehouse, so the package works with every adapter supported by dbt v2.

!!! note "Using dbt Core?"

    Version 2 requires dbt `>=2.0.0`. If you are on dbt Core, stay on version 1.x of the package, which is implemented as models in your warehouse. The documentation for 1.x is available in the version selector of this site, and the code is on the [`v1.4.0` tag](https://github.com/dbt-labs/dbt-project-evaluator/tree/v1.4.0).

## Why version 2?

- **Native.** The rules are dbt checks, not models: you run them with `dbt check`, list them with `dbt ls --resource-type check`, and configure their severity, tags or whether they run in `dbt_project.yml`, as for any other resource.
- **Checked before every build.** Checks run before anything compiles on `dbt build`, so a rule set to `severity: error` stops a build that breaks it, instead of reporting after the fact.
- **Fast.** Nothing is built and nothing is read in your warehouse. On a project of about 1,900 models, all the checks take about 15 seconds, parsing included, against about 2 minutes for the version 1 `dbt build` on Snowflake.
- **Selectable.** `dbt check --select` and `state:modified` only report the violations on the resources you changed, which is what a pull request needs. Version 1 always evaluated the whole project.
- **No warehouse needed.** No credentials, no compute cost, the same result for every adapter, and CI that doesn't need secrets.
- **Smaller and easier to extend.** There is no dependency and no per-adapter code. A check is a short SQL query (6 lines for the median) over the same information schema that you can query yourself, so you can [write your own](querying-the-dag.md) next to the package's.

## Using This Package

### Cloning via dbt Package Hub

Check [dbt Hub](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

```yaml title="packages.yml"
packages:
  - package: dbt-labs/dbt_project_evaluator
    version: [">=2.0.0", "<3.0.0"]
```

The package has no dependency on other packages and doesn't need any additional setup in your project: the `info_schema` configuration required by checks is declared by the package itself.

### How It Works

Each rule is a SQL file in the [`checks` folder](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/checks) of the package. A check returns one row per violation (no row means the check passes) and is run in DuckDB against the information schema of your project: `models`, `sources`, `edges`, `data_tests`, `exposures`... The query results are the same whatever adapter you use.

Once the package is installed:

- the checks run automatically before every `dbt build`
- you can run them on demand with `dbt check`

```shell
dbt check                                  # every check
dbt check fct_root_models                  # a single check
dbt check --select staging                 # only report violations on the selected resources
dbt check --select state:modified --state path/to/main/target   # only what the pull request changes
dbt ls --resource-type check --select tag:modeling
```

All the checks are **advisory by default** (`severity: warn`). Each check returns the resource to fix as `unique_id`, so `--select` restricts the rows reported by a check to the selected resources. The two coverage checks, `fct_documentation_coverage` and `fct_test_coverage`, are project-wide metrics and always evaluate the whole project (they are configured with `selection_filter_on: none`). `--state` is not needed in a dbt platform CI job, see [running as a CI check](ci-check.md).

Each warning indicates the presence of a type of misalignment. To troubleshoot a misalignment:

1. Locate the related documentation in the [list of rules](rules.md)
2. Read the `dbt check` output, which lists the first resources that violate the rule (see [reading the output of `dbt check`](customization/issues-in-log.md))
3. Either fix the issue(s) or [accept them as exceptions](customization/exceptions.md)

### Configuration

Every check is tagged with `dbt_project_evaluator` and with its category (`modeling`, `testing`, `documentation`, `structure`, `performance` or `governance`), and its configuration can be overridden from the `checks:` section of your `dbt_project.yml`, for a whole category or for a single check:

```yaml title="dbt_project.yml"
checks:
  dbt_project_evaluator:
    structure:                  # a whole category
      +severity: error          # block `dbt build` when a rule is violated
    documentation:
      fct_undocumented_models:
        +enabled: false         # a single rule
```

See [running as a CI check](ci-check.md) and [disabling checks](customization/customization.md) for more details. Thresholds and naming conventions are configured with [variables](customization/overriding-variables.md), and resources can be [excluded](customization/excluding-packages-and-paths.md) based on their package or path.

### Differences from 1.x

Moving from version 1? See [migrating to version 2](migrating-to-v2.md).

#### Major changes

- **dbt >= 2.0.0 only.** dbt Core users stay on 1.x.
- **Nothing is built in the warehouse.** The checks run locally on the metadata of your project, so they work with every adapter, don't materialize anything and don't need `dbt_utils`. The 1.x `models:`, `seeds:` and `dispatch:` configuration of the package is deleted.
- **You can check selected resources only.** `dbt check --select …`, including `state:modified`, only reports the violations on the selected resources, see [running as a CI check](ci-check.md). In 1.x the whole project was always evaluated. The two coverage checks stay project-wide.
- **Severity is set with `checks:`** in `dbt_project.yml` (per category or per check) instead of the tests severity and the `DBT_PROJECT_EVALUATOR_SEVERITY` environment variable. The checks run before `dbt build`, or on demand with `dbt check`, and report the violations themselves: the `print_dbt_project_evaluator_issues` `on-run-end` macro is gone.
- **Exceptions are a var or a macro.** The `dbt_project_evaluator_exceptions` seed is replaced by the variable (or macro) of the same name, because checks can't read seeds. It can also filter on a column of the check, to accept a given parent or pair. See [configuring exceptions](customization/exceptions.md); the [migration script](migrating-to-v2.md) converts the seed.
- **Hard-coded references** are reported by `dbt lint`: turn on the rule [`DBT05`](https://docs.getdbt.com/reference/commands/lint#dbt-specific-rules), see [hard coded references](rules/modeling.md#hard-coded-references).
- **The DAG tables are gone**, including `int_all_dag_relationships`. To query your DAG, use the information schema directly, see [querying the DAG](querying-the-dag.md).

#### Minor changes

These don't change what is reported.

- `fct_missing_primary_key_tests` doesn't count `not_null` column constraints as `not_null` tests yet. This is a short-term limitation: constraints aren't available to checks ([dbt-labs/dbt#16553](https://github.com/dbt-labs/dbt/issues/16553)).
- `exclude_paths_from_project` is now a case-sensitive substring match rather than a regular expression, and applies to the resources of all packages. `exclude_packages` works as in 1.x, including `["all"]`, and never excludes your own project, see [excluding packages and paths](customization/excluding-packages-and-paths.md).
- Disabled resources (models, sources, seeds, snapshots and tests) are ignored by all the checks.
- Sources are identified by their `unique_id`. Two sources with the same name in two different packages are therefore two different resources, while 1.x grouped them together.
- `fct_direct_join_to_source`, `fct_multiple_sources_joined`, `fct_model_fanout` and `fct_source_fanout` return the names of the parents or children in a list column, not their number.
- `fct_undocumented_sources` and `fct_duplicate_sources` report one row per source.
- `fct_documentation_coverage` and `fct_test_coverage` only return a row when the coverage is below the target, and ignore exceptions.
- `fct_test_directories` compares the directory of the YAML file where the tests of a model are defined with the directory of the model. The location of each individual test isn't available when the project is parsed.
- The variables `insert_batch_size`, `max_depth_dag`, `comment_chars`, `token_costs` and `use_native_agate_printing` have been removed.
