## Test dbt Project

The models within this folder (barring those in models/audit_schema_tests) represent a dbt project with poor DAG modeling. Error detection tools within this package are tested on this dbt project.

<img width="1311" alt="DAG of the test dbt project" src="https://user-images.githubusercontent.com/91074396/157699532-d9029568-e6f0-48df-a09d-d7a9bc299ab5.png">

## Adding an Integration Test
Create a seed which matches the intended output of your model and add equality tests comparing the output to your seed to the output of your model.
