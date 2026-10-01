# Reading the violations in the logs

In version 1, the violations had to be displayed in the logs with an `on-run-end` hook. In version 2, `dbt check` and `dbt build` report the violations themselves, and the macro `print_dbt_project_evaluator_issues` (as well as the variable `use_native_agate_printing`) doesn't exist anymore.

## Output of `dbt check`

For each check that finds violations, dbt prints the number of violations followed by a table with the first rows returned by the check:

```text
[warning] [CheckWarned (dbt1651)]: check 'fct_root_models' found with 1 violation(s)
┌────────────────────────────────────────────────────────┬───────────────┬────────────────────────────────┐
│ unique_id                                              ┆ name          ┆ original_file_path             │
╞════════════════════════════════════════════════════════╪═══════════════╪════════════════════════════════╡
│ model.my_project.dim_hardcoded                         ┆ dim_hardcoded ┆ models/marts/dim_hardcoded.sql │
└────────────────────────────────────────────────────────┴───────────────┴────────────────────────────────┘
```

- the message starts with `CheckWarned` for the checks configured with `severity: warn` and with `CheckFailed` for the ones configured with `severity: error`
- the first column, `unique_id`, is the resource to fix. The other columns depend on the check and give more context (the parent, the expected path, the number of children...)
- only the first rows are displayed. To see the other ones, restrict the check to a part of your project with `--select`, for example `dbt check fct_undocumented_models --select staging`

## Getting the results in JSON

With `--log-format json`, every log line is a JSON document, which makes it easy to consume the results programmatically, for example with `jq`:

```bash
# one line per check with violations: name and number of violations
dbt check --log-format json 2>/dev/null \
  | jq -r 'select(.info.name == "CheckWarned" or .info.name == "CheckFailed") | .info.msg | split("\n")[0]'
```

This is particularly useful for:

- **CI/CD pipelines**: parse the results and fail builds based on specific violations
- **Custom dashboards**: ingest the number of violations over time into a monitoring tool
- **LLM-powered automation**: feed the results to an LLM to analyze the violations and suggest fixes

The `msg` field also contains the table with the first rows of each check. The complete list of resources returned by a check can be retrieved by narrowing down the selection, as explained above.

## Logging your custom rules

The checks you define in your own project (see [defining additional checks](../querying-the-dag.md#defining-additional-checks-that-match-your-exact-requirements)) are reported in the same way as the ones from this package.
