# Configuring exceptions to the rules

While the rules defined in this package are considered best practices, we realize that there might be exceptions to those rules and people might want to exclude given results to get passing checks despite not following all the recommendations.

An example would be excluding all models with names matching with `stg_..._unioned` from `fct_multiple_sources_joined` as we might want to union 2 different tables representing the same data in some of our staging models and we don't want the check to report those models.

!!! warning "The exceptions seed has been removed"

    Version 1 of the package offered the seed `dbt_project_evaluator_exceptions.csv` to list the results to ignore for a given rule. Checks run when the project is parsed and can't read seeds, so this seed doesn't exist in version 2. The options below replace it, with different granularity.

## Choosing the right option

| You want to... | Use |
| -------------- | --- |
| stop evaluating a rule entirely | [disable the check](customization.md) |
| keep a rule but not block the build when it is violated | keep its severity at `warn` (the default), see [running as a CI check](../ci-check.md) |
| ignore a package, a folder or some models/sources for **all** the rules | [`exclude_packages` and `exclude_paths_from_project`](excluding-packages-and-paths.md) |
| ignore some resources for a given run or job | `--exclude` or `--selector` |

There is currently no way to ignore a resource for a **single** rule only while still evaluating it for the others.

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
