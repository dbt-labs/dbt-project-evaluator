# Configuring dbt_project_evaluator

All of this goes in the **root project's** `dbt_project.yml`.

## Severity, enabling and disabling checks

Checks default to `severity: warn`. They are organized in one folder per category (`modeling`, `testing`, `documentation`, `structure`, `performance`, `governance`), and tagged with `dbt_project_evaluator` and the category.

```yaml
checks:
  dbt_project_evaluator:
    +severity: error              # every check
    structure:
      +severity: warn             # a category
    testing:
      +enabled: false             # disable a category
    modeling:
      fct_model_fanout:
        +enabled: false           # disable one check
      fct_root_models:
        +severity: error          # one check
```

Severity can follow the environment: `+severity: "{{ env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn') }}"` with `DBT_PROJECT_EVALUATOR_SEVERITY=error` set in CI.

Keys such as `meta` are rejected on checks (`UnusedConfigKey`): use `enabled`, `severity` and tags.

## Variables

Set under `vars:` (top level, or under the package name `dbt_project_evaluator:`).

| Variable | Default | Used by |
| -------- | ------- | ------- |
| `documentation_coverage_target` | `100` | `fct_documentation_coverage` reports when the percentage of documented models is below it |
| `test_coverage_target` | `100` | `fct_test_coverage`, same for tested models |
| `models_fanout_threshold` | `3` | `fct_model_fanout`: minimum number of direct leaf children |
| `too_many_joins_threshold` | `7` | `fct_too_many_joins`: minimum number of direct parents |
| `chained_views_threshold` | `5` | `fct_chained_views_dependencies`: distance above which a chain of views is flagged |
| `primary_key_test_macros` | `[["dbt.test_unique", "dbt.test_not_null"], ["dbt_utils.test_unique_combination_of_columns"]]` | `fct_missing_primary_key_tests`: each inner list is a way to test a primary key |
| `enforced_primary_key_node_types` | `["model"]` | resource types that need a tested primary key (`model`, `source`, `snapshot`, `seed`) |
| `model_types` | `['base','staging','intermediate','marts','other']` | model types; add a type `x` with `x_folder_name` and/or `x_prefixes` |
| `<type>_folder_name` | `base`, `staging`, `intermediate`, `marts` | folder that makes a model of that type |
| `<type>_prefixes` | `['base_']`, `['stg_']`, `['int_']`, `['fct_','dim_']`, `['rpt_']` (`other`) | name prefixes of that type |
| `exclude_packages` | `[]` | packages to ignore |
| `exclude_paths_from_project` | `[]` | paths or names to ignore |
| `dbt_project_evaluator_exceptions` | `{}` | accepted violations, see [exceptions.md](exceptions.md) |

Raising a threshold to silence a check is a decision for the user, not a fix.

## Excluding packages and paths

Excluded resources are ignored by every check.

```yaml
vars:
  exclude_packages: ["upstream_package"]      # or ["all"] for every package but the root project
  exclude_paths_from_project: ["models/legacy/", "raw_crm.contacts"]
```

- The root project is never excluded by `exclude_packages`, and `dbt_project_evaluator` itself always is.
- `exclude_paths_from_project` values are literal substrings, compared case-sensitively with the file path and the `unique_id` (a `/` in the value is removed before comparing with the `unique_id`). `%` and `_` are wildcards. They apply to all packages, and they are not regular expressions.
- Disabled models, sources, seeds, snapshots and tests are always ignored.

## CI

- `dbt build` evaluates the checks first; checks at `severity: error` stop it before anything is built.
- `dbt check` runs only the checks; they are evaluated locally on the project metadata, not in the warehouse.
- In CI, set `error` for the checks that must block merges, run `dbt check --select state:modified --state <artifacts of the base branch>` (no `--state` on a dbt platform CI job), and run the checks that report sources without `--select`.
