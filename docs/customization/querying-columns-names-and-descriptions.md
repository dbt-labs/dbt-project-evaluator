# Querying columns names and descriptions with SQL

The model `stg_columns` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/staging/graph/stg_columns.sql)), created with the package, lists all the columns configured in all the dbt nodes (models, sources, tests, snapshots).

It will not list the columns of the models that have not explicitly been added to the YAML files.

You can use this model to help with questions such as:

- Are there columns with the same name in different nodes?
- Do any columns in the YAML configuration lack descriptions?
- Do any columns share the same name but have different descriptions?
- Are there columns with names that match a specific pattern (regex)?
- Have any prohibited names been used for columns?


## Defining additional tests that match your exact requirements

You can create a custom test against  `{{ ref(stg_columns) }}` to test for your specific check! When running the package you'd need to make sure to also include children of the package's models by using the `package:dbt_project_evalutator+` selector.
