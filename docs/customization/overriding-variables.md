# Overriding Variables

Currently, this package uses different variables to adapt the checks to your objectives and naming conventions. They can all be updated directly in `dbt_project.yml`, either at the top level of `vars` or under the name of the package (`dbt_project_evaluator`).

The severity of the checks, or whether a check is enabled, are not variables but configurations of the checks, see [running as a CI check](../ci-check.md) and [disabling checks](customization.md).

## Testing and Documentation Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `test_coverage_target` | the minimum acceptable test coverage percentage | 100% |
| `documentation_coverage_target` | the minimum acceptable documentation coverage percentage | 100% |
| `primary_key_test_macros` | the set(s) of dbt tests used to check validity of a primary key | `[["dbt.test_unique", "dbt.test_not_null"], ["dbt_utils.test_unique_combination_of_columns"]]` |
| `enforced_primary_key_node_types` | the set of node types for you you would like to enforce primary key test coverage. Valid options to include are `model`, `source`, `snapshot`, `seed` | `["model"]`

**Usage notes for `primary_key_test_macros:`**

The `primary_key_test_macros` variable determines how the `fct_missing_primary_key_tests` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/checks/testing/fct_missing_primary_key_tests.sql)) check evaluates whether the models in your project are properly tested for their grain. This variable is a list and each entry **must be a list of test names in `project_name.test_macro_name` format**.

For each entry in the parent list, the check will evaluate whether each model has all of the tests in that entry applied to the same column (or to the model itself for tests defined at the model level). If a model meets the criteria of any of the entries in the parent list, it will be considered a pass. The default behavior for this package will check for whether each model has either:

1. **Both** the `not_null` and `unique` tests applied to a single column OR
2. The `dbt_utils.unique_combination_of_columns` applied to the model.

Each set of test(s) that define a primary key requirement must be grouped together in a sub-list to ensure they are evaluated together (e.g. [`dbt.test_unique`, `dbt.test_not_null`] ).

!!! note

    Version 1 also counted a `not_null` column constraint as a `not_null` test. In version 2, only the tests are counted, because constraints are not available in the information schema when the checks run. Use a `not_null` test (it can be added next to the constraint).

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
| `model_types` | a list of the different types of models that define the layers of your dbt project | base, staging, intermediate, marts, other |
| `base_folder_name` | the name of the folder that contains your base models | base |
| `staging_folder_name` | the name of the folder that contains your staging models | staging |
| `intermediate_folder_name` | the name of the folder that contains your intermediate models | intermediate |
| `marts_folder_name` | the name of the folder that contains your marts models | marts |
| `base_prefixes` | the list of acceptable prefixes for your base models | base_ |
| `staging_prefixes` | the list of acceptable prefixes for your staging models | stg_ |
| `intermediate_prefixes` | the list of acceptable prefixes for your intermediate models | int_ |
| `marts_prefixes` | the list of acceptable prefixes for your marts models | fct_, dim_ |
| `other_prefixes` | the list of acceptable prefixes for your other models | rpt_ |

The `model_types`, `<model_type>_folder_name`, and `<model_type>_prefixes` variables allow the package to check if models in the different layers are in the correct folders and have a correct prefix in their name. The default model types are the ones we recommend in our [dbt Labs Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md).

The type of a model is the one implied by its prefix. If its name doesn't match any prefix, it is the one implied by the deepest folder of its path matching one of the `<model_type>_folder_name`, and `other` when there is none.

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
| `chained_views_threshold` | threshold for unacceptable length of chain of views for `fct_chained_views_dependencies` | 5 |

```yaml title="dbt_project.yml"
vars:
  dbt_project_evaluator:
    # set your chained views threshold to 8 instead of 5
    chained_views_threshold: 8
```

## Exclusion Variables

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `exclude_packages` | the packages to exclude from all the checks | none |
| `exclude_paths_from_project` | the paths (or `unique_id`) to exclude from all the checks | none |

See [excluding packages and paths](excluding-packages-and-paths.md) for the details.

## Variables removed in version 2

The variables `insert_batch_size`, `max_depth_dag`, `comment_chars`, `token_costs` and `use_native_agate_printing` configured the models created in the warehouse by version 1 (unpacking of the graph, recursive DAG, SQL complexity and printing of the violations in the logs). They don't exist anymore and can be removed from your `dbt_project.yml`.
