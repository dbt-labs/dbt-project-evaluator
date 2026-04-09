select * from {{ ref('dbt_project_evaluator', 'int_all_dag_relationships') }}
