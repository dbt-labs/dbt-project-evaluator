# Displaying violations in the logs

This package provides a macro that can be executed via an `on-run-end` hook to display the package results in the logs in addition to storing those in the Data Warehouse.

To use it, you can add the following line in your `dbt_project.yml`:

```yaml
on-run-end: "{{ dbt_project_evaluator.print_dbt_project_evaluator_issues() }}"
```

The macro accepts two parameters:

- to pick between 2 types of formatting, set `format='table'` (default) or `format='csv'`
- to add quotes to the database and schema (default = no quote), set ``quote='`'`` or `quote='"'`

## Logging your custom rules

You can also log the results of your custom rules by applying `dbt_project_evaluator.is_empty` to
the custom models.

```yaml
models:
  - name: my_custom_rule_model
    description: This is my custom project evaluator check 
    data_tests:
      - dbt_project_evaluator.is_empty
```
