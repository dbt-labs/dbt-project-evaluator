## Test dbt Project

The models within this folder (barring those in models/audit_schema_tests) represent a dbt project with poor DAG modeling. Error detection tools within this package are tested on this dbt project.

<img width="1377" alt="DAG of the test dbt project" src="https://user-images.githubusercontent.com/73915542/170353654-58ad303c-adaa-49f6-86b8-723543eb2d3d.png">

## Adding an Integration Test
Create a seed which matches the intended output of your model and add equality tests comparing the output to your seed to the output of your model.
