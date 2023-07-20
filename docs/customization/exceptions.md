# Configuring exceptions to the rules

While the rules defined in this package are considered best practices, we realize that there might be exceptions to those rules and people might want to exclude given results to get passing tests despite not following all the recommendations.

An example would be excluding all models with names matching with `stg_..._unioned` from `fct_multiple_sources_joined` as we might want to union 2 different tables representing the same data in some of our staging models and we don't want the test to fail for those models.

The package offers the ability to define a seed called `dbt_project_evaluator_exceptions.csv` to list those exceptions we don't want to be reported. This seed must contain the following columns:

- `fct_name`: the name of the fact table for which we want to define exceptions (Please note that it is not possible to exclude specific models for all the `coverage` tests, but there are variables available to configure those to the particular users' needs)
- `column_name`: the column name from `fct_name` we will be looking at to define exceptions
- `id_to_exclude`: the values (or `like` pattern) we want to exclude for `column_name`
- `comment`: a field where people can document why a given exception is legitimate

The following section describes the steps to follow to configure exceptions.

## 1. Create a new seed

With our previous example, the seed `dbt_project_evaluator_exceptions.csv` would look like:

```csv
fct_name,column_name,id_to_exclude,comment
fct_multiple_sources_joined,child,stg_%_unioned,Models called _unioned can union multiple sources
```

which looks like the following when loaded in the warehouse

|fct_name                   |column_name|id_to_exclude   |comment                                           |
|---------------------------|-----------|----------------|--------------------------------------------------|
|fct_multiple_sources_joined|child      |stg\_%\_unioned |Models called \_unioned can union multiple sources|

## 2. Deactivate the seed from the original package

Only a single seed can exist with a given name. When using a custom one, we need to deactivate the blank one from the package by adding the following to our `dbt_project.yml`

```yaml title="dbt_project.yml"
seeds:
  dbt_project_evaluator:
    dbt_project_evaluator_exceptions:
      +enabled: false
```

## 3. Run the seed and the package

We then run both the seed and the package by executing the following command:

```bash
dbt build --select package:dbt_project_evaluator dbt_project_evaluator_exceptions
```
