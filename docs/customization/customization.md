# Disabling checks from the package

!!! note

    This section is describing how to completely deactivate checks from the package.
    If you are looking to deactivate models/sources from being checked, you can look at [excluding packages and paths](excluding-packages-and-paths.md)

All the rules of the package are native [dbt checks](https://docs.getdbt.com/docs/build/checks), organized in one folder per category: `modeling`, `testing`, `documentation`, `structure`, `performance` and `governance`.

If there is a particular check or set of checks that you *do not want this package to execute*, you can
disable them as you would any other resource in your `dbt_project.yml` file, using the `checks:` section

``` yaml title="dbt_project.yml"
checks:
  dbt_project_evaluator:
    testing:
      # disable all the checks from a category
      +enabled: false
    modeling:
      # disable a single check
      fct_model_fanout:
        +enabled: false
```

The checks are also tagged with `dbt_project_evaluator` and with the name of their category, so you can list them with `dbt ls`:

```bash
dbt ls --resource-type check --select tag:modeling
```

The same section is used to [change the severity](../ci-check.md) of the checks:

``` yaml title="dbt_project.yml"
checks:
  dbt_project_evaluator:
    +severity: error
```
