# Disabling checks from the package

!!! note

    This section is describing how to completely deactivate tests from the package.
    If you are looking to deactivate models/sources from being tested, you can look at [excluding packages and paths](excluding-packages-and-paths.md)

All the tests done as part of the package are tied to `fct` models.

If there is a particular test or set of tests that you *do not want this package to execute*, you can
disable the corresponding `fct` models as you would any other model in your `dbt_project.yml` file

``` yaml title="dbt_project.yml"
models:
  dbt_project_evaluator:
    marts:
      data_tests:
        # disable entire test coverage suite
        +enabled: false
      dag:
        # disable single DAG model
        fct_model_fanout:
          +enabled: false
```
