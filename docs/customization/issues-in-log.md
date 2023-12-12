# Displaying violations in the logs

This package provides a macro that can be executed via an `on-run-end` hook to display the package results in the logs in addition to storing those in the Data Warehouse.

To use it, you can add the following line in your `dbt_project.yml`:

```yaml
on-run-end: "{{ dbt_project_evaluator.print_dbt_project_evaluator_issues() }}"
```

The macro accepts two parameters:

- to pick between 2 types of formatting, set `format='table'` (default) or `format='csv'`
- to add quotes to the database and schema (default = no quote), set ``quote='`'`` or `quote='"'`
