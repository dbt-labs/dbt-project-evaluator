with 

all_nodes as (
    select * from {{ ref('stg_all_graph_resources') }} 
    
)

select
    node_id,
    node_name,
    is_described,
    resource_type,
    file_path

from all_nodes 
where not is_described and resource_type = 'model'