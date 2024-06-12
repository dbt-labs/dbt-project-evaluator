{{ config(severity = env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn')) }}
/*
NYT has large volume & size datasets.
Almost all models should be incremental materializations over tables. 
Flag any mopdels >10MM rows or 50GB size

Incremental modelling makes my head hurt, but saves a lot of money $$$.  Read the docs again.
https://docs.getdbt.com/docs/build/incremental-strategy
*/
select 
    stg_nodes.*,
    tables_metadata.row_count,
    tables_metadata.size_bytes
from {{ ref("stg_nodes") }}
left outer join `{{ model.database }}.{{ model.schema }}.__TABLES__` as tables_metadata
    on tables_metadata.project_id = stg_nodes.database
    and tables_metadata.dataset_id = stg_nodes.schema
    and tables_metadata.table_id = stg_nodes.alias -- use name instead?
where
    materialized = 'table'
    --only return large tables 10MM records or 50GB
    and (
        tables_metadata.row_count>9999999
        or tables_metadata.size_bytes > 4999999999
    )
