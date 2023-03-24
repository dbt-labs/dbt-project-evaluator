# Displaying violations in the logs

This package provides a macro that can be executed via an `on-run-end` hook to display the package results in the logs in addition to storing those in the Data Warehouse.

To use it, you can add the following line in your `dbt_project.yml`:

```yaml
on-run-end: "{{ dbt_project_evaluator.print_dbt_project_evaluator_issues() }}"
```

In the case that you are storing the tables with the package results in a schema or database different from the default ones from your profile, the following parameters are available for `print_dbt_project_evaluator_issues()`:

- `schema_project_evaluator`: the schema where the tables are stored
- `db_project_evaluator`: the database where the tables are stored
