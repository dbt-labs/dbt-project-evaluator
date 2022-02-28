-- TO DO: consider changing name to stg_all_graph_resources and all references to "node" to "resource" (example: node_id -> resource_id)
    -- this would help prevent confusion between this model and base__nodes
-- one row for each node in the graph
with 

enabled_nodes as (
    select 
        unique_id as node_id,
        node_name,
        resource_type,
        file_path,
        case 
            when resource_type in ('test') then null
            when file_path like '%{{ var('staging_folder_name', 'staging') }}%' or node_name like '%staging%' or node_name like '%stg%' then 'staging'
            when file_path like '%{{ var('marts_folder_name', 'marts') }}%' then 'marts'
            else null
        end as model_type 
    from {{ ref('base__nodes')}}
    where is_enabled
    -- and package_name != 'pro-serv-dag-auditing'
),

exposures as (
    select 
        unique_id as node_id,
        node_name,
        resource_type,
        file_path,
        null as model_type
    from {{ ref('base__exposures')}}
),

metrics as (
    select 
        unique_id as node_id,
        node_name,
        resource_type,
        file_path
    from {{ ref('base__metrics')}}
),

sources as (
    select 
        unique_id as node_id,
        source_name || '.' || node_name as node_name,
        resource_type,
        file_path,
        null as model_type
    from {{ ref('base__sources')}}
),

all_dag_nodes as (
    select * from enabled_nodes

    union all

    select * from exposures

    union all

    select * from metrics

    union all

    select * from sources

)

select * from all_dag_nodes