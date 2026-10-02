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
- only the first 5 rows are displayed. To see all of them, use [the `show_violations.py` script](#seeing-every-violation-of-a-check)

## Seeing every violation of a check

When a check finds more than 5 violations, run the script that comes with the package for that check. It prints every row, not only the first 5:

```shell
dbt check                                    # 1. find the checks with more than 5 violations
python dbt_packages/dbt_project_evaluator/scripts/show_violations.py fct_undocumented_models   # 2. list all of them
```

The script runs `dbt check` for the check you name, then runs the query of the check in DuckDB. It needs the `duckdb` command line or the `duckdb` Python package (`uv run --with duckdb dbt_packages/dbt_project_evaluator/scripts/show_violations.py ...` installs it on the fly). Use `python3` instead of `python` on macOS and Linux if `python` is not found, or `py` on Windows.

The options it does not know, such as `--vars`, `--target` or `--profiles-dir`, are passed to `dbt check`, so the check sees the same variables and [exceptions](exceptions.md) as in your own run.

| Option | |
|---|---|
| `--format <format>` | `table` (the default), `markdown`, `csv` or `json`. `csv` and `json` are meant for other tools |
| `--where "<condition>"` | Keep only some of the violations, with a SQL condition on the columns of the check, for example `--where "original_file_path like 'models/staging/%'"` |
| `--no-run` | Write the SQL to `target/check_violations/<check>.sql` without running it. You can then run it yourself, with `duckdb -box < target/check_violations/<check>.sql`, or open it in the DuckDB UI |

`dbt check` applies `--select` (and `state:modified`) to the rows of a check, not to its query. The script therefore shows the violations of the whole project, even if you pass it `--select`. Use `--where` to keep the ones you want.

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

The `msg` field also contains the table with the first 5 rows of each check. To get all the rows of a check, use [the `show_violations.py` script](#seeing-every-violation-of-a-check) with `--format json`.

## Logging your custom rules

The checks you define in your own project (see [defining additional checks](../querying-the-dag.md#defining-additional-checks-that-match-your-exact-requirements)) are reported in the same way as the ones from this package.
