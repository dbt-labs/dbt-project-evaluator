select * from {{ ref('dbt_project_evaluator', 'stg_naming_convention_folders') }}
