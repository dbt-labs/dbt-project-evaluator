# Disabling Models

If there is a particular model or set of models that you *do not want this package to execute*, you can
disable these models as you would any other model in your `dbt_project.yml` file

``` yaml title="dbt_project.yml"
models:
  dbt_project_evaluator:
    marts:
      tests:
        # disable entire test coverage suite
        +enabled: false
      dag:
        # disable single DAG model
        fct_model_fanout:
          +enabled: false

```
