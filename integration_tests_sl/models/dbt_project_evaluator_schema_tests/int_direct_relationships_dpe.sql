select * from {{ ref('dbt_project_evaluator', 'int_direct_relationships') }}
