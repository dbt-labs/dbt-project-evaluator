{{ config(severity = env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn')) }}
/*
Any table larger than 1MM records or 50GB should set copy_partions=true
Avoid full table scans when insert-overwrite is used.

Any model with incremental strategy set to insert_overwrite can get large cost
reductions with one parameter change .
https://docs.getdbt.com/blog/bigquery-ingestion-time-partitioning-and-partition-copy-with-dbt
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
    and coalesce(json_value(partition_by, '$.data_type'), '') 
        in ('date', 'timestamp')
    and coalesce(
        json_value(replace(partition_by, ": True", ": 'True'"), '$.copy_partitions'), ''
        ) = 'True'
    -- only return large tables 1MM records or 50GB
    and (
        tables_metadata.row_count>999999
        or tables_metadata.size_bytes > 4999999999

    )
    -- Work to do:  Fix the boolean replace function upstream in the forked
    -- project_evaluator packagev
