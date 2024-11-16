# dbt_project_evaluator

This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices.
Specifically, this package tests for:

1. __[Modeling](rules/modeling)__ - your dbt DAG for modeling best practices
2. __[Testing](rules/testing)__ - your models for testing best practices
3. __[Documentation](rules/documentation)__ - your models for documentation best practices
4. __[Structure](rules/structure)__ - your dbt project for file structure and naming best practices
5. __[Performance](rules/performance)__ - your model materializations for performance best practices
6. __[Governance](rules/governance)__ - your model governance feature best practices


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

## Using This Package

### Cloning via dbt Package Hub
  
Check [dbt Hub](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

### Additional setup for Databricks/Spark/DuckDB/Redshift

In your `dbt_project.yml`, add the following config:

```yaml title="dbt_project.yml"
dispatch:
  - macro_namespace: dbt
    search_order: ['dbt_project_evaluator', 'dbt']
```

This is required because the project currently overrides a small number of dbt core macros in order to ensure the project can run across the listed adapters. The overridden macros are in the [cross_db_shim directory](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/macros/cross_db_shim/).
  
### How It Works

This package will:

1. Parse your [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) object and write it into your warehouse as a series of models (see [models/marts/core](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/core))
2. Create another series of models that each represent one type of misalignment in your project (below you can find a full list of each misalignment and its accompanying model)
3. Test those models to alert you to the presence of the misalignment

Once you've installed the package, all you have to do is run a `dbt build --select package:dbt_project_evaluator`

Each test warning indicates the presence of a type of misalignment. To troubleshoot a misalignment:

1. Locate the related documentation
2. Query the associated model to find the specific instances of the issue within your project or set up an [`on-run-end` hook](https://docs.getdbt.com/reference/project-configs/on-run-start-on-run-end) to display the rules violations in the dbt logs (see [displaying violations in the logs](customization/issues-in-log.md))
3. Either fix the issue(s) or [customize](customization/exceptions.md) the package to exclude them

----

## Limitations

### BigQuery and Databricks

BigQuery current support for recursive CTEs is limited and Databricks SQL doesn't support recursive CTEs.

For those Data Warehouses, the model `int_all_dag_relationships` needs to be created by looping CTEs instead. The number of loops is configured with `max_depth_dag` and defaulted to 9. This means that dependencies between models of more than 9 levels of separation won't show in the model `int_all_dag_relationships` but tests on the DAG will still be correct. With a number of loops higher than 9 BigQuery sometimes raises an error saying the query is too complex.
