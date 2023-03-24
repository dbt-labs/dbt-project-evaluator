# Overriding Variables

Currently, this package uses different variables to adapt the models to your objectives and naming conventions. They can all be updated directly in `dbt_project.yml`

## Testing and Documentation Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `test_coverage_target` | the minimum acceptable test coverage percentage | 100% |
| `documentation_coverage_target` | the minimum acceptable documentation coverage percentage | 100% |
| `primary_key_test_macros` | the set(s) of dbt tests used to check validity of a primary key | `[["dbt.test_unique", "dbt.test_not_null"], ["dbt_utils.test_unique_combination_of_columns"]]` |

**Usage notes for `primary_key_test_macros:`**

The `primary_key_test_macros` variable determines how the `fct_missing_primary_key_tests` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/tests/fct_missing_primary_key_tests.sql)) model evaluates whether the models in your project are properly tested for their grain. This variable is a list and each entry **must be a list of test names in `project_name.test_macro_name` format**.

For each entry in the parent list, the logic in `int_model_test_summary` will evaluate whether each model has all of the tests in that entry applied. If a model meets the criteria of any of the entries in the parent list, it will be considered a pass. The default behavior for this package will check for whether each model has either:

1. **Both** the `not_null` and `unique` tests applied to a single column OR
2. The `dbt_utils.unique_combination_of_columns` applied to the model.

Each set of test(s) that define a primary key requirement must be grouped together in a sub-list to ensure they are evaluated together (e.g. [`dbt.test_unique`, `dbt.test_not_null`] ).

*While it's not explicitly tested in this package, we strongly encourage adding a `not_null` test on each of the columns listed in the `dbt_utils.unique_combination_of_columns` tests.*

```yaml title="dbt_project.yml"
# set your test and doc coverage to 75% instead
# use the dbt_constraints.test_primary_key test to check for validity of your primary keys

vars:
  dbt_project_evaluator:
    documentation_coverage_target: 75
    test_coverage_target: 75
    primary_key_test_macros: [["dbt_constraints.test_primary_key"]]
    
```

## DAG Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `models_fanout_threshold` | threshold for unacceptable model fanout for `fct_model_fanout` | 3 models |

```yaml title="dbt_project.yml"
# set your model fanout threshold to 10 instead of 3

vars:
  dbt_project_evaluator:
    models_fanout_threshold: 10
```

## Naming Convention Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `model_types` | a list of the different types of models that define the layers of your dbt project | staging, intermediate, marts, other |
| `staging_folder_name` | the name of the folder that contains your staging models | staging |
| `intermediate_folder_name` | the name of the folder that contains your intermediate models | intermediate |
| `marts_folder_name` | the name of the folder that contains your marts models | marts |
| `staging_prefixes` | the list of acceptable prefixes for your staging models | stg_ |
| `intermediate_prefixes` | the list of acceptable prefixes for your intermediate models | int_ |
| `marts_prefixes` | the list of acceptable prefixes for your marts models | fct_, dim_ |
| `other_prefixes` | the list of acceptable prefixes for your other models | rpt_ |

The `model_types`, `<model_type>_folder_name`, and `<model_type>_prefixes` variables allow the package to check if models in the different layers are in the correct folders and have a correct prefix in their name. The default model types are the ones we recommend in our [dbt Labs Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md).

If your model types are different, you can update the `model_types` variable and create new variables for `<model_type>_folder_name` and/or `<model_type>_prefixes`.

```yaml title="dbt_project.yml"
# add an additional model type "util"

vars:
  dbt_project_evaluator:
    model_types: ['staging', 'intermediate', 'marts', 'other', 'util']
    util_folder_name: 'util'
    util_prefixes: ['util_']
```

## Performance Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `chained_views_threshold` | threshold for unacceptable length of chain of views for `fct_chained_views_dependencies` | 4 |
| `insert_batch_size` | number of records inserted per batch when unpacking the graph into models | 10000 |

```yaml title="dbt_project.yml"
vars:
  dbt_project_evaluator:
    # set your chained views threshold to 8 instead of 4
    chained_views_threshold: 8
    # update the number of records inserted from the graph from 10,000 to 500 to reduce query size
    insert_batch_size: 500
```

## Warehouse Specific Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `max_depth_dag` | limits the number of looped CTEs when computing the DAG end-to-end for BigQuery and Databricks/Spark compatibility | 9 |

Changing `max_depth_dag` number to a higher one might prevent the package from running properly on BigQuery and Databricks/Spark.
