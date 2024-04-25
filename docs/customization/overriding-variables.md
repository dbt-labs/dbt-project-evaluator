# Overriding Variables

Currently, this package uses different variables to adapt the models to your objectives and naming conventions. They can all be updated directly in `dbt_project.yml`

## Testing and Documentation Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `test_coverage_target` | the minimum acceptable test coverage percentage | 100% |
| `documentation_coverage_target` | the minimum acceptable documentation coverage percentage | 100% |
| `primary_key_test_macros` | the set(s) of dbt tests used to check validity of a primary key | `[["dbt.test_unique", "dbt.test_not_null"], ["dbt_utils.test_unique_combination_of_columns"]]` |
| `enforced_primary_key_node_types` | the set of node types for you you would like to enforce primary key test coverage. Valid options to include are `model`, `source`, `snapshot`, `seed` | `["model"]`

**Usage notes for `primary_key_test_macros:`**

The `primary_key_test_macros` variable determines how the `fct_missing_primary_key_tests` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/tests/fct_missing_primary_key_tests.sql)) model evaluates whether the models in your project are properly tested for their grain. This variable is a list and each entry **must be a list of test names in `project_name.test_macro_name` format**.

For each entry in the parent list, the logic in `int_model_test_summary` will evaluate whether each model has all of the tests in that entry applied. If a model meets the criteria of any of the entries in the parent list, it will be considered a pass. The default behavior for this package will check for whether each model has either:

1. **Both** the `not_null` and `unique` tests applied to a single column OR
2. The `dbt_utils.unique_combination_of_columns` applied to the model.

Each set of test(s) that define a primary key requirement must be grouped together in a sub-list to ensure they are evaluated together (e.g. [`dbt.test_unique`, `dbt.test_not_null`] ).

*While it's not explicitly tested in this package, we strongly encourage adding a `not_null` test on each of the columns listed in the `dbt_utils.unique_combination_of_columns` tests. Alternatively, on Snowflake, consider `dbt_constraints.test_primary_key` in the [dbt Constraints](https://github.com/Snowflake-Labs/dbt_constraints) package, which enforces each field in the primary key is non null.*

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

| variable    | description  | default     |
| ----------- | ------------ | ----------- |
| `models_fanout_threshold`  | threshold for unacceptable model fanout for `fct_model_fanout` | 3 models |
| `too_many_joins_threshold` | threshold for the number of references to flag in `fct_too_many_joins` | 7 references |

```yaml title="dbt_project.yml"
# set your model fanout threshold to 10 instead of 3 and too many joins from 6 instead of 7

vars:
  dbt_project_evaluator:
    models_fanout_threshold: 10
    too_many_joins_threshold: 6
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

```yaml title="dbt_project.yml"
vars:
  dbt_project_evaluator:
    # set your chained views threshold to 8 instead of 4
    chained_views_threshold: 8
```

## SQL code analysis

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `comment_chars` | a list of strings used for inline comments | `["--"]` |
| `token_costs` | a dictionary of SQL tokens (words) and associated complexity weight, <br>used to estimate models complexity | see in the `dbt_project.yml` file of the package |

## Execution

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `max_depth_dag` | limits the maximum distance between nodes calculated in `int_all_dag_relationships` | 9 for bigquery and spark, -1 for other adatpters |
| `insert_batch_size` | number of records inserted per batch when unpacking the graph into models | 10000 |

**Note on max_depth_dag**

The default behavior for limiting the relationships calculated in the `int_all_dag_relationships` model differs depending on your adapter.

- For Bigquery & Spark/Databricks the maximum distance between two nodes in your DAG, calculated in `int_all_dag_relationships`, is set by the `max_depth_dag` variable, which is defaulted to 9. So by default, `int_all_dag_relationships` contains a row for every path less than or equal to 9 nodes in length between two nodes in your DAG. This is because these adapters do not currently support recursive SQL, and queries often fail on more than 9 recursive joins.
- For all other adapters `int_all_dag_relationships` by default contains a row for every single path between two nodes in your DAG. If you experience long runtimes for the `int_all_dag_relationships` model, you may consider limiting the length of your generated DAG paths. To do this, set `max_depth_dag: {{ whatever limit you want to enforce }}`. The value of `max_depth_dag` must be greater than 2 for all DAG tests to work, and greater than `chained_views_threshold` to ensure your performance tests to work. By default, the value of this variable for these adapters is -1, which the package interprets as "no limit".

```yaml title="dbt_project.yml"
vars:
  dbt_project_evaluator:
    # update the number of records inserted from the graph from 10,000 to 500 to reduce query size
    insert_batch_size: 500
    # set the maximum distance between nodes to 5 
    max_depth_dag: 5
```
