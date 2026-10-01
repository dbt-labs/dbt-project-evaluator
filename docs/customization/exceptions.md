# Configuring exceptions to the rules

While the rules defined in this package are considered best practices, we realize that there might be exceptions to those rules and people might want to exclude given results to get passing checks despite not following all the recommendations.

An example would be excluding all models with names matching with `stg_..._unioned` from `fct_multiple_sources_joined` as we might want to union 2 different tables representing the same data in some of our staging models and we don't want the check to report those models.

This is what the variable `dbt_project_evaluator_exceptions` is for. It replaces the seed `dbt_project_evaluator_exceptions.csv` of version 1, see [migrating to version 2](../migrating-to-v2.md) to convert an existing seed.

## Accepting violations of a check

The exceptions are a mapping from the **name of a check** to a **list of patterns**:

```yaml
fct_multiple_sources_joined:
  - stg_%_unioned
fct_root_models:
  - dim_calendar
```

Each row returned by a check points at the resource to fix in its column `unique_id`. The row is dropped when this resource matches one of the patterns of the check. Patterns use the SQL [`LIKE`](https://duckdb.org/docs/sql/functions/pattern_matching#like) syntax (`%` matches any sequence of characters, `_` any single character) and are case-sensitive. A pattern is compared with the name of the resource, and with its whole `unique_id`:

| Resource | Name to match | Example pattern |
| -------- | ------------- | --------------- |
| model, seed, snapshot, exposure | `name` | `stg_legacy_%` |
| versioned model | `name.vVERSION`, the bare name doesn't match | `int_model_5.v1` |
| source table | `source_name.table_name` | `raw_shop.orders` |
| anything | the `unique_id` | `model.my_project.stg_legacy_orders` or `model.%.stg_legacy_%` |

To find the name to use, run the check (`dbt check fct_root_models`): the `unique_id` column of the output is the resource that is matched.

There are two ways to provide the exceptions.

### In a variable

This is the simplest option. Define the variable in your `dbt_project.yml`, either at the top level of `vars` or under the name of the package:

```yaml title="dbt_project.yml"
vars:
  dbt_project_evaluator_exceptions:
    fct_multiple_sources_joined:
      - stg_%_unioned
    fct_unused_sources:
      - raw_shop.unused_table
```

### In a macro

If the list gets long, or if you want to document every exception, define the macro `default__dbt_project_evaluator_exceptions` in your project. The package calls the macro `dbt_project_evaluator_exceptions` with [`adapter.dispatch`](https://docs.getdbt.com/reference/dbt-jinja-functions/dispatch), which looks for an implementation in your project first. The variable above is only the default implementation: once you define the macro, it is not read anymore, unless your macro does.

Write the exceptions as YAML in a string and parse them with `fromyaml`, so that you can use YAML comments:

```sql title="macros/dbt_project_evaluator_exceptions.sql"
{% macro default__dbt_project_evaluator_exceptions() %}

{% set exceptions %}

# stg_..._unioned models union identical sources on purpose
fct_multiple_sources_joined:
  - stg_%_unioned

# the sources of the legacy CRM are kept for audit and not used yet
fct_unused_sources:
  - raw_shop.unused_table         # source_name.table_name
  - legacy_crm.%

# a pattern is also compared with the whole unique_id
fct_model_naming_conventions:
  - model.%.orders_summary

{% endset %}

{{ return(fromyaml(exceptions)) }}

{% endmacro %}
```

The macro can return anything that builds the same mapping. For example, to complete the variable with a list written in YAML instead of replacing it:

```sql title="macros/dbt_project_evaluator_exceptions.sql"
{% macro default__dbt_project_evaluator_exceptions() %}

{% set exceptions = var('dbt_project_evaluator_exceptions', {}) %}

{% for check_name, patterns in fromyaml(more_exceptions()).items() %}
  {% do exceptions.update({check_name: (exceptions.get(check_name) or []) + patterns}) %}
{% endfor %}

{{ return(exceptions) }}

{% endmacro %}


{% macro more_exceptions() %}
fct_unused_sources:
  - raw_shop.unused_table
{% endmacro %}
```

### Names of checks are validated

The exceptions are checked every time the project is parsed. An entry that isn't the name of a check of the package, because of a typo for example, is a compile error that lists the names that exist:

```
dbt_project_evaluator_exceptions: 'fct_modl_fanout' is not a check of dbt_project_evaluator. Known checks: fct_chained_views_dependencies, fct_direct_join_to_source, ...
```

### What exceptions can't do

- An exception removes a **row**, which points at a single resource. It can't accept a relationship between two resources, like "this model is allowed to read this source": for checks that report the child of an edge (like `fct_direct_join_to_source`), the exception is on the child.
- `fct_documentation_coverage` and `fct_test_coverage` are measures of the whole project, not lists of resources, so they ignore the exceptions. To remove resources from them, use `exclude_packages` or `exclude_paths_from_project`.
- `fct_hard_coded_references` isn't part of version 2, so there is nothing to configure.

## Other ways to ignore results

Exceptions apply to a single check. The other options below apply to more:

| You want to... | Use |
| -------------- | --- |
| accept some violations of a given rule | the [exceptions](#accepting-violations-of-a-check) above |
| stop evaluating a rule entirely | [disable the check](customization.md) |
| keep a rule but not block the build when it is violated | keep its severity at `warn` (the default), see [running as a CI check](../ci-check.md) |
| ignore a package, a folder or some models/sources for **all** the rules | [`exclude_packages` and `exclude_paths_from_project`](excluding-packages-and-paths.md) |
| ignore some resources for a given run or job | `--exclude` or `--selector`, see below |

## Ignoring resources in a given run

The rows reported by a check are restricted to the resources selected by `--select` and `--exclude`, because each check returns the resource to fix in the column `unique_id`:

```bash
# all the checks, except for the models in the legacy folder
dbt check --exclude path:models/legacy

# a single check, without the models called stg_<...>_unioned
dbt check fct_multiple_sources_joined --exclude "stg_*_unioned"
```

To make it permanent, define the selection in a YAML [selector](https://docs.getdbt.com/reference/node-selection/yaml-selectors) and use it with `--selector`:

```yaml title="selectors.yml"
selectors:
  - name: evaluated_resources
    definition:
      method: fqn
      value: "*"
      exclude:
        - method: path
          value: models/legacy
```

```bash
dbt check --selector evaluated_resources
```

!!! note

    `fct_documentation_coverage` and `fct_test_coverage` always evaluate the whole project (`selection_filter_on: none`). To exclude resources from those two checks, use `exclude_packages` or `exclude_paths_from_project`.
