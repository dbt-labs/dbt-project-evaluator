# Displaying violations in the logs

This package provides a macro that can be executed via an `on-run-end` hook to display the package results in the logs in addition to storing those in the Data Warehouse.

To use it, you can add the following line in your `dbt_project.yml`:

```yaml
on-run-end: "{{ dbt_project_evaluator.print_dbt_project_evaluator_issues() }}"
```

The macro accepts two parameters:

- to pick between 3 types of formatting, set `format='table'` (default), `format='csv'`, or `format='json'`
- to add quotes to the database and schema (default = no quote), set ``quote='`'`` or `quote='"'`

## Using with dbt Cloud CLI, dbt Cloud IDE, or dbt Fusion

The default implementation uses agate's `print_table()` and `print_csv()` functions. However, these don't work in all environments:

| Environment | `format='table'` | `format='csv'` | `format='json'` |
| ----------- | ---------------- | -------------- | --------------- |
| dbt Core | native | native | Jinja |
| dbt Fusion | native | **Jinja required** | Jinja |
| dbt Cloud CLI | Jinja required | Jinja required | Jinja |
| dbt Cloud IDE | Jinja required | Jinja required | Jinja |

If you're using dbt Cloud CLI or dbt Cloud IDE, or if you want to use `format='csv'` with dbt Fusion, set the following variable in your `dbt_project.yml`:

```yaml
vars:
  use_native_agate_printing: false
```

This will use a pure Jinja implementation that works across all environments.

## JSON output for automation

The `format='json'` option outputs results as a single JSON array, making it easy to pipe to tools like `jq` or consume programmatically.

**Example output:**

```json
[
  {
    "test_name": "dbt_project_evaluator.marts.dag.is_empty_fct_model_fanout_",
    "results": [
      {"resource_name": "my_model", "num_dependents": 5}
    ]
  },
  {
    "test_name": "dbt_project_evaluator.marts.tests.is_empty_fct_missing_primary_key_tests_",
    "results": [
      {"resource_name": "stg_orders", "resource_type": "model"}
    ]
  }
]
```

### Getting clean JSON output

To get valid JSON that can be piped to other tools, combine `format='json'` with dbt's `--quiet` (or `-q`) flag. This suppresses dbt's usual log output:

```bash
dbt build --select package:dbt_project_evaluator -q | jq '.'
```

This is particularly useful for:

- **CI/CD pipelines**: Parse results programmatically and fail builds based on specific violations
- **LLM-powered automation**: Feed the JSON output to an LLM to analyze violations and suggest fixes automatically
- **Custom dashboards**: Ingest results into monitoring tools or databases
- **Filtering with jq**: Extract specific tests or results

```bash
# Get all test names
dbt build --select package:dbt_project_evaluator -q | jq '.[].test_name'

# Get results for a specific test
dbt build --select package:dbt_project_evaluator -q | jq '.[] | select(.test_name | contains("fanout"))'

# Count total violations
dbt build --select package:dbt_project_evaluator -q | jq '[.[].results | length] | add'
```

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
