select * from {{ ref('dbt_project_evaluator', 'int_model_test_summary') }}
