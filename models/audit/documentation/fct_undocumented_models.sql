with 

all_nodes as (
    select * from {{ ref('stg_all_graph_nodes') }} 
    
)

select * from all_nodes 
where not is_described and resource_type = 'model'