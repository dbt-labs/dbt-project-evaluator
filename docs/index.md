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

To avoid repeating the same filters and joins, the checks are built on top of three shared relations defined in [`macros/checks`](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/macros/checks):

- `evaluator_models()`: the models in scope (not disabled, not excluded), typed with the [naming convention variables](customization/overriding-variables.md#naming-convention-variables)
- `evaluator_sources()`: the sources in scope
- `evaluator_edges()`: the direct dependencies between the resources in scope (tests are not included), with the name, type, materialization and access of both ends

Once the package is installed:

- the checks run automatically before every `dbt build`
- you can run them on demand with `dbt check`

```shell
dbt check                                  # every check
dbt check fct_root_models                  # a single check
dbt check --select staging                 # only report violations on the selected resources
dbt ls --resource-type check --select tag:modeling
```

All the checks are **advisory by default** (`severity: warn`). Each check returns the resource to fix as `unique_id`, so `--select` restricts the rows reported by a check to the selected resources. The two coverage checks, `fct_documentation_coverage` and `fct_test_coverage`, are project-wide metrics and always evaluate the whole project (they are configured with `selection_filter_on: none`).

Each warning indicates the presence of a type of misalignment. To troubleshoot a misalignment:

1. Locate the related documentation in the [list of rules](rules.md)
2. Read the `dbt check` output, which lists the first resources that violate the rule (see [reading the output of `dbt check`](customization/issues-in-log.md))
3. Either fix the issue(s) or [customize](customization/exceptions.md) the package to exclude them

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

- `fct_hard_coded_references` has been removed, because it needs the SQL code of the models and this isn't available to checks. The `dbt lint` rule [`DBT05`](https://docs.getdbt.com/reference/commands/lint#dbt-specific-rules) (`dbt.hard_coded_reference`) partly covers it, see [hard coded references](rules/modeling.md#hard-coded-references).
- The `dbt_project_evaluator_exceptions` seed isn't supported, because checks can't read seeds. See [other ways to exclude results](customization/exceptions.md).
- `fct_missing_primary_key_tests` doesn't count `not_null` column constraints as `not_null` tests, because constraints aren't available in the information schema at check time.
- The warehouse models are gone, including `int_all_dag_relationships`. To query your DAG, use the information schema directly, see [querying the DAG](querying-the-dag.md).
- The `print_dbt_project_evaluator_issues` `on-run-end` macro is gone. `dbt check` and `dbt build` report the violations themselves.
- `exclude_paths_from_project` is now a case-sensitive substring match rather than a regular expression, and `exclude_packages: ["all"]` isn't supported anymore, see [excluding packages and paths](customization/excluding-packages-and-paths.md).
- Disabled resources (models, sources, seeds, snapshots and tests) are ignored by all the checks.
- Sources are identified by their `unique_id`. Two sources with the same name in two different packages are therefore two different resources, while 1.x grouped them together.
- `fct_undocumented_sources` reports one row per source.
- `fct_test_directories` compares the directory of the YAML file where the tests of a model are defined with the directory of the model. The location of each individual test isn't available when the project is parsed.
- The variables `insert_batch_size`, `max_depth_dag`, `comment_chars`, `token_costs` and `use_native_agate_printing` have been removed.
