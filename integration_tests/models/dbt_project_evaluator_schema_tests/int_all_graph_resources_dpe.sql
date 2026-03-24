select * from {{ ref('dbt_project_evaluator', 'int_all_graph_resources') }}
