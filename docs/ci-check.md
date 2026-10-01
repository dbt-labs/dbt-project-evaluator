# Running this package as a CI check

Once you have addressed all current misalignments in your project (either by fixing them or [excluding them](customization/exceptions.md)), you can use this package as a CI check to ensure code changes don't introduce new misalignments.

Since the rules are native dbt checks, there is nothing to build in your warehouse: the checks run when the project is parsed, and a check configured with `severity: error` makes the command fail when it finds violations.

## 1. Make the checks fail in CI

By default, the checks in this package are configured with "warn" severity: they report the violations but don't make `dbt check` or `dbt build` fail. You can set the severity for the whole package, for a category of checks or for an individual check in your `dbt_project.yml`:

```yaml title="dbt_project.yml"
checks:
  dbt_project_evaluator:
    +severity: error              # every check
    documentation:
      +severity: warn             # but only warn for a whole category
      fct_undocumented_models:
        +severity: error          # except for this one
```

To only make the checks fail in CI, you can use an environment variable, set to "error" in the CI environment and left unset everywhere else:

```yaml title="dbt_project.yml"
checks:
  dbt_project_evaluator:
    +severity: "{{ env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn') }}"
```

!!! note

    You can follow a similar process to disable checks in some environments, using `+enabled` instead of `+severity`.

## 2. Run the checks for each pull request

The checks are executed at the beginning of `dbt build`, so a CI job running `dbt build` already evaluates your project. When a check with `severity: error` finds violations, `dbt build` fails before building any model.

You can also run only the checks, without building anything, with

```bash
dbt check
```

The command exits with a non-zero code when a check configured with `severity: error` returns rows.

### Only reporting the violations on the modified resources

Each check returns the resource to fix in the column `unique_id`, which allows `--select` to restrict the violations reported to the selected resources. Combined with `state:modified` and a manifest from your main branch, this reports the violations introduced by the pull request and ignores the existing ones:

```bash
dbt check --select state:modified --state path/to/main/target
```

For example, after modifying the model `stg_orders`, the checks that look at individual resources (`fct_undocumented_models`, `fct_missing_primary_key_tests`...) only report `stg_orders`.

!!! note

    `fct_documentation_coverage` and `fct_test_coverage` measure the whole project and not individual resources. They are configured with `selection_filter_on: none` and are therefore always evaluated on the entire project, whatever `--select` is set to.

!!! warning

    With dbt 2.0.6, `dbt check --select` cannot scope source rows ([dbt-labs/dbt#16554](https://github.com/dbt-labs/dbt/issues/16554)), so `state:modified` does not pick up a changed source. The checks that report sources (`fct_unused_sources`, `fct_sources_without_freshness`, `fct_undocumented_source_tables`, `fct_undocumented_sources`, `fct_duplicate_sources`, `fct_source_directories`, `fct_source_fanout`) therefore report nothing when a selector is set. Run them without `--select` (for example in a separate, non-blocking step) to catch source violations.

### Example with GitHub Actions

The following workflow parses the base branch of the pull request to get a manifest to compare to, then runs the checks on the modified resources:

```yaml title=".github/workflows/dbt_project_evaluator.yml"
name: dbt project evaluator

on: pull_request

jobs:
  checks:
    runs-on: ubuntu-latest
    env:
      DBT_PROJECT_EVALUATOR_SEVERITY: error
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - run: pip install "dbt>=2.0.0,<3.0.0"

      - name: Parse the base branch to get the state to compare to
        run: |
          git worktree add ../base "origin/${{ github.base_ref }}"
          cd ../base
          dbt deps
          dbt parse

      - run: dbt deps

      - name: Check the modified resources
        run: dbt check --select state:modified --state ../base/target
```

!!! note

    The `dbt parse` and `dbt check` commands need a valid profile for your project. If your CI is orchestrated by dbt Cloud, make sure the CI job is [set up with deferral](https://docs.getdbt.com/docs/deploy/continuous-integration) so that `state:modified` has a state to compare to.
