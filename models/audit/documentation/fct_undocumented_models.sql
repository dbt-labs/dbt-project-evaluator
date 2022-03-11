with 

all_resources as (
    select * from {{ ref('stg_all_graph_resources') }} 
    
)

select
    resource_id,
    resource_name,
    is_described,
    resource_type,
    file_path

from all_resources 
where not is_described and resource_type = 'model'