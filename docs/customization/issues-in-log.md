# Displaying violations in the logs

This package provides a macro that can be executed via an `on-run-end` hook to display the package results in the logs in addition to storing those in the Data Warehouse.

To use it, you can add the following line in your `dbt_project.yml`:

```yaml
on-run-end: "{{ dbt_project_evaluator.print_dbt_project_evaluator_issues() }}"
```

The macro accepts two parameters:

- to pick between 2 types of formatting, set `format='table'` (default) or `format='csv'`
- to add quotes to the database and schema (default = no quote), set ``quote='`'`` or `quote='"'`

## Logging your custom rules

You can also log the results of your custom rules by applying `dbt_project_evaluator.is_empty` to
the custom models.

Here is the example code:

```yaml
# {{ your dbt project dir }}/models/dbt_project_evaluator/fct_public_models_without_exposures.sql

with
    public_models as (
        select *
        from {{ ref("dbt_project_evaluator", "int_all_graph_resources") }}
        where resource_type = 'model' and is_public and not is_excluded
    ),
    models_with_exposure as (
        select direct_parent_id as resource_id
        from {{ ref("dbt_project_evaluator", "base_exposure_relationships") }}
    ),
    final as (
        select resource_name as model_name, is_public, false as has_exposure
        from public_models m
        where
            not exists (
                select 1 from models_with_exposure e where m.resource_id = e.resource_id
            )
    )

select *
from final {{ dbt_project_evaluator.filter_exceptions(model.name) }} -- to enable exceptions
```

```yaml
# {{ dbt project dir }}/models/dbt_project_evaluator/governance.yml

models:
  - name: fct_public_models_without_exposures
    description: This table shows each public model that does not have an exposure
    tests:
      - dbt_project_evaluator.is_empty
```

By setting `dbt_project_evaluator.is_empty`, you can see the result like:

```
### List of issues raised by dbt_project_evaluator ###

-- my_dbt_package.dbt_project_evaluator.dbt_project_evaluator_is_empty_fct_public_models_without_exposures_ --
| MODEL_NAME                         | IS_PUBLIC | HAS_EXPOSURE |
| ---------------------------------- | --------- | ------------ |
| fct_my_public_model                |      True |        False |


-- dbt_project_evaluator.marts.governance.is_empty_fct_public_models_without_contract_ --
| RESOURCE_NAME                      | IS_PUBLIC | IS_CONTRACT_ENFORCED |
| ---------------------------------- | --------- | -------------------- |
| fct_my_public_model                |      True |                False |
```

Custom rules and official rules can be identified by the test name prefix (`my_dbt_package.` and
`dbt_project_evaluator.`).
