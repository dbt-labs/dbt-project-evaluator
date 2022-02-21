-- one row for each node in the DAG
with 

models_and_snapshots as (
    select 
        unique_id as node_id,
        node_name,
        resource_type,
        file_path
    from {{ ref('base__nodes')}}
    where resource_type in ('model','snapshot')
    -- and package_name != 'pro-serv-dag-auditing'
),

exposures as (
    select 
        unique_id as node_id,
        node_name,
        resource_type,
        file_path
    from {{ ref('base__exposures')}}
),

sources as (
    select 
        unique_id as node_id,
        node_name,
        resource_type,
        file_path
    from {{ ref('base__sources')}}
),

all_dag_nodes as (
    select * from models_and_snapshots

    union all

    select * from exposures

    union all

    select * from sources

),

final as (
    select 
        node_id,
        node_name,
        resource_type,
        file_path
)

select * from all_dag_nodes