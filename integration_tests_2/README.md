## Test dbt Project

The models within this folder are used for testing use cases that can't be checked as part of the other `integration_tests` project. No tests are defined as the main purpose is to ensure that all models run properly in specific situations.

Currently, this project is used to test the package behavior when:
- there is no exposure
- there is no metric
- people don't override the default seed for `dbt_project_evaluator_exceptions`
