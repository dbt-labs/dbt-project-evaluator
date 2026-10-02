---
name: using-dbt-project-evaluator
description: Use when running, selecting, configuring or accepting violations of the dbt_project_evaluator package version 2 (native dbt checks named fct_*), for example "run dbt check", "only check the models I changed", "make the evaluator fail the build", "disable a check", "change a threshold", "exclude a package or folder", "accept this violation", "add an exception" or "add the evaluator to CI". Covers exceptions (dbt_project_evaluator_exceptions). Hands off to fixing-dbt-project-evaluator-violations to actually fix violations, and does not migrate from version 1 (use migrating-dbt-project-evaluator-to-v2).
---

# Using dbt_project_evaluator (version 2)

Every rule of the package is a native dbt check that runs on the project metadata, locally, without touching the warehouse. A check returns one row per violation, and its `unique_id` column is the resource to fix.

## 1. Confirm the setup

- Run `dbt --version`: version 2 needs dbt 2.0.0 or later. On dbt v1 (1.x) the package is version 1 and this skill does not apply.
- Check `packages.yml` for `dbt-labs/dbt_project_evaluator` with a `2.x` version, then run `dbt deps` if `dbt_packages/dbt_project_evaluator` is missing.

## 2. Run the checks

```shell
dbt check                              # every check, whole project
dbt check fct_root_models              # one check
dbt check fct_root_models --select staging   # one check, only the resources selected
dbt ls --resource-type check --select tag:modeling   # list checks by category tag
```

- `dbt build` runs the checks first. A check with `severity: error` that finds violations stops the build; the default severity is `warn`.
- Read the output: `check 'x' found with N violation(s)` (`warn`) or `failed with N violation(s)` (`error`), followed by a table.
- Only the **first 5 rows** of each check are printed. To see all the rows of one check, run `python dbt_packages/dbt_project_evaluator/scripts/show_violations.py <check> --format csv` (needs the `duckdb` command line or Python package; `--where "<sql condition>"` keeps some rows; options it does not know, like `--vars`, go to `dbt check`). It shows the whole project even with `--select`.
- `dbt check` exits with a failure only if a check at severity `error` has violations (or a check could not run).

## 3. Check only what changed

```shell
dbt check --select state:modified --state path/to/main/target   # outside the dbt platform
dbt check --select state:modified                               # dbt platform CI job: state comes from deferral
```

Per-resource checks then report only the changed resources. `fct_documentation_coverage` and `fct_test_coverage` always evaluate the whole project.

Known limitation (dbt 2.0.6): `dbt check --select` cannot scope the checks that report **sources** (`fct_unused_sources`, `fct_sources_without_freshness`, `fct_undocumented_source_tables`, `fct_undocumented_sources`, `fct_duplicate_sources`, `fct_source_directories`, `fct_source_fanout`); with a selector they report nothing, and `state:modified` does not see a changed source. Run them without `--select`. Tracked in https://github.com/dbt-labs/dbt/issues/16554.

## 4. Fixing violations

To fix the violations a check reports, use the fixing-dbt-project-evaluator-violations skill. Prefer fixing over silencing: do **not** add an exception, disable a check or raise a threshold to make a violation go away unless the user asks for it or confirms that the violation is intentional.

## 5. Configure

Severity, enabling and disabling use the `checks:` block of the root `dbt_project.yml`; thresholds, naming conventions and exclusions are vars. Details and examples: [references/configuration.md](references/configuration.md).

```yaml
checks:
  dbt_project_evaluator:
    structure:
      +severity: error            # a whole category (modeling, testing, documentation, structure, performance, governance)
    modeling:
      fct_model_fanout:
        +enabled: false           # a single check
```

## 6. Accept a violation (exceptions)

Use exceptions only when the user confirms the violation is intentional. Exceptions are a mapping from a check name to entries, given in the var `dbt_project_evaluator_exceptions` or by overriding the macro `default__dbt_project_evaluator_exceptions()`. An entry is a pattern on the resource (`- stg_legacy_%`) or a mapping on a column of the check (`- {name: stg_a, parent: stg_b}`). Formats, every rule and examples: [references/exceptions.md](references/exceptions.md). After adding one, run the check and confirm the count dropped by exactly what you expected.

## 7. CI

```shell
dbt deps
dbt check --select state:modified --state ../main-artifacts    # changed resources only
dbt check fct_unused_sources fct_sources_without_freshness fct_undocumented_source_tables fct_undocumented_sources fct_duplicate_sources fct_source_fanout fct_source_directories   # source checks, without --select
```

Set the severity of the checks that should block merges to `error` in `dbt_project.yml`.

## Pitfalls

- A check name that is not a check of the package in the exceptions is a compile error that lists the valid names: copy names and columns from [references/check-columns.md](references/check-columns.md).
- `_` in a pattern is a LIKE wildcard, patterns are case-sensitive, and versioned models are named `name.v2`.
- `exclude_paths_from_project` is a literal substring match (not a regular expression) applied to every package.
- Disabled models, sources and tests are ignored by the checks, as in version 1.
