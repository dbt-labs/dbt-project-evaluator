select * from {{ ref('dbt_project_evaluator', 'stg_columns') }}
