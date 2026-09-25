# dbt_project_evaluator

This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices.
Specifically, this package tests for:

1. __[Modeling](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/modeling/)__ - your dbt DAG for modeling best practices
2. __[Testing](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/testing)__ - your models for testing best practices
3. __[Documentation](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/documentation)__ - your models for documentation best practices
4. __[Structure](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/structure)__ - your dbt project for file structure and naming best practices
5. __[Performance](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/performance)__ - your model materializations for performance best practices
6. __[Governance](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/governance)__ - your best practices for model governance features.

In addition to tests, this package creates the model `int_all_dag_relationships` which holds information about your DAG in a tabular format and can be queried using SQL in your Warehouse.

Currently, the following adapters are supported:

- BigQuery
- Databricks/Spark
- PostgreSQL
- Redshift
- Snowflake
- DuckDB
- Trino (tested with Iceberg connector)
- AWS Athena (tested manually)
- Greenplum (tested manually)
- ClickHouse (tested manually)
- Microsoft Fabric Data Warehouse (tested manually)
- Microsoft Fabric Spark (tested manually)

## Using This Package

### Fusion native checks (v2)

Version 2 includes native, parse-time project checks for 28 of the package's 29
rules. Installing the package does not enable them automatically. Fusion users
can disable the legacy warehouse models and opt into all native checks from the
root project's `dbt_project.yml`:

```yml
models:
  dbt_project_evaluator:
    +enabled: false

checks:
  dbt_project_evaluator:
    +enabled: true
```

The checks are advisory by default. Root-project configuration can enable one
rule at a time or override `severity`; see [the native-check guide](checks/README.md)
for package-wide and selective examples. The existing model-based implementation
remains available for dbt Core projects.

### Cloning via dbt Package Hub
  
Check [dbt Hub](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

### Additional setup for Databricks/Spark/DuckDB/Redshift/ClickHouse/Fabric

In your `dbt_project.yml`, add the following config:

```yml
# dbt_project.yml

dispatch:
  - macro_namespace: dbt
    search_order: ['dbt_project_evaluator', 'dbt']
```

This is required because the project currently overrides a small number of dbt core macros in order to ensure the project can run across the listed adapters. The overridden macros are in the [cross_db_shim directory](macros/cross_db_shim/).
  
## Documentation

The full documentation and list of rules are available on [this website](https://dbt-labs.github.io/dbt-project-evaluator/)
