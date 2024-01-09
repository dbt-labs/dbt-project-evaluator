# Testing

## Missing Primary Key Tests

`fct_missing_primary_key_tests`
([Source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/tests/fct_missing_primary_key_tests.sql))
lists every model that does not meet the minimum testing requirement of testing primary keys.
Any model that does not have either

1. a `not_null` test and a `unique` test applied to a single column OR
2. a `dbt_utils.unique_combination_of_columns` test applied to a set of columns

it will be flagged by this model.

### Reason to Flag

Tests are assertions you make about your models and other resources in your dbt project
(e.g., sources, seeds and snapshots).
Defining tests is a great way to confirm that your code is working correctly,
and helps prevent regressions when your code changes.
Models without proper tests on their grain are a risk to the reliability and scalability of your project.

### How to Remediate

Apply a [uniqueness test](https://docs.getdbt.com/reference/resource-properties/tests#unique) and a [not null test](https://docs.getdbt.com/reference/resource-properties/tests#not_null) to the column that represents the grain of your model in its schema entry. For models that are unique across a combination of columns, we recommend adding a surrogate key column to your model, then applying these tests to that new model. See the [`surrogate_key`](https://github.com/dbt-labs/dbt-utils#surrogate_key-source) macro from dbt_utils for more info! Alternatively, you can use the [`dbt_utils.unique_combination_of_columns`](https://github.com/dbt-labs/dbt-utils#unique_combination_of_columns-source) test from `dbt_utils`. Check out the [overriding variables section](../customization/overriding-variables.md) to read more about configuring other primary key tests for your project!

Additional tests can be configured by applying a [generic test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#generic-tests) in the model's `.yml` entry or by creating a [singular test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#singular-tests)
in the `tests` directory of you project.

### Enforcing on more node types(Advanced)

You can optionally extend this test to apply to more node types (`source`,`snapshot`, `seed`).
By configuring the variable `enforced_primary_key_node_types`
to be a set of node types for which you wish to enforce primary key test coverage in addition to
(or instead of) just models.
Check out the [overriding variables section](../customization/overriding-variables.md) for instructions

Snapshots should always have a multi-field primary key to function, while sources and seeds may not.
Depending on your expectations for duplicates and null values, different kinds of primary key tests may be appropriate.
Consider your use case carefully.

---

## Test Coverage

`fct_test_coverage` ([Source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/tests/fct_test_coverage.sql))
contains metrics pertaining to project-wide test coverage.
Specifically, this models measures:

1. `test_coverage_pct`: the percentage of your models that have minimum one test applied.
2. `test_to_model_ratio`: the ratio of the number of tests in your dbt project to the number of models in your dbt project
3. `<model_type>_test_coverage_pct`: the percentage of each of your model types that have minimum one test applied.

This model will raise a `warn` error on a `dbt build` or `dbt test` if the `test_coverage_pct` is less than 100%.
You can set your own threshold by overriding the `test_coverage_target` variable.
You can adjust your own model types by overriding the `model_types` variable. [See overriding variables section.](../customization/overriding-variables.md)

### Reason to Flag

We recommend that every model in your dbt project has tests applied to ensure the accuracy of your data transformations.

### How to Remediate

Apply a [generic test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#generic-tests) in the model's `.yml` entry, or create a [singular test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#singular-tests)
in the `tests` directory of you project.

As explained above, we recommend [at a minimum](https://www.getdbt.com/analytics-engineering/transformation/data-testing/#what-should-you-test), every model should have `not_null` and `unique` tests set up on a primary key.
