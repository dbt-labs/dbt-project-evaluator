# Querying the DAG with SQL

The model `int_all_dag_relationships` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/core/int_all_dag_relationships.sql)), created with the package, lists all the dbt nodes (models, exposures, sources, metrics, seeds, snapshots) along with all their dependencies (including indirect ones) and the path between them.

Building additional models and snapshots on top of this model could allow:

## Creating a dashboard that provides info on your project

- a list of all the sources used by a given exposure
- a list of all the exposures or metrics using a given source
- the dependencies between different models

## Building metrics/KPIs on top of a dbt project

- evolution of the number of models over time
- evolution of the number of metrics and exposures over time

## Getting insights on potential refactoring work

- identifying models with a lot of lines of code
- identifying the models with the highest level of complexity leveraging the column `sql_complexity` from the table `int_all_graph_resources`, based on the weights defined in the `token_costs` variable
- looking at the longest "chains" of models in a project
- reviewing models with many/few direct dependents
- identifying potential bottlenecks

## Defining additional tests that match your exact requirements

- writing a model with `ref(int_all_dag_relationships)` with custom tests added for a specific use case
