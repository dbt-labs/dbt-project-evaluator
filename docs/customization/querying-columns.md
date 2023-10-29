# Querying columns with SQL

The model `int_all_columns` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/core/int_all_columns.sql)), created with the package, lists all the columns from all the dbt nodes (models, sources, seeds, snapshots, analyses)

You can use this model to help with questions such as:

- Are there columns with the same name in different nodes?
- Are there columns that lack descriptions?
- Do any columns share the same name but have different descriptions?
- Are there columns with names that match a specific pattern (regex)?
- Have any prohibited names been used for columns?


## Defining additional tests that match your exact requirements

You can create a custom test against  `{{ ref(int_all_columns) }}` to test for your specific check! When running the package you'd need to make sure to also include children of the packag's models by using the `package:dbt_project_evalutator+` selector.