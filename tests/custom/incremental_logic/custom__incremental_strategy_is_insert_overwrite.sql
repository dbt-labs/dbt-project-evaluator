{{ config(severity = env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn')) }}
/*
NYT has large volume & size datasets.
Almost all models should have incremental models set to insert-overwrite strategy.
Merging records is not performant over large datasets.  
Append only is performant, but rarely useful.

Incremental modelling makes my head hurt, but saves a lot of money $$$.  Read the docs again.
https://docs.getdbt.com/docs/build/incremental-strategy
*/
select 
    stg_nodes.unique_id,
    stg_nodes.name,
    stg_nodes.resource_type,
    stg_nodes.materialized,
    stg_nodes.on_schema_change,
    stg_nodes.incremental_strategy,
    stg_nodes.partiton_by,
    stg_nodes.full_refresh,
    tables_metadata.row_count,
    tables_metadata.size_bytes
from {{ ref("stg_nodes") }}
left outer join `{{ model.database }}.{{ model.schema }}.__TABLES__` as tables_metadata
    on tables_metadata.project_id = stg_nodes.database
    and tables_metadata.dataset_id = stg_nodes.schema
    and tables_metadata.table_id = stg_nodes.alias -- use name instead?
where
    materialized = 'incremental'
    and coalesce(incremental_strategy,'') not in ('append','insert_overwrite') 
    -- only return large tables 1MM records or 50GB
    and (
        tables_metadata.row_count>999999
        or tables_metadata.size_bytes > 4999999999
    )
