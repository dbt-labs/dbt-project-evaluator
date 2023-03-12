with 

all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where 
        resource_type != 'test'
        and resource_yml_file_path is not null
),

final as (

    select 
        resource_yml_file_path, 
        count(distinct resource_type) as total_resource_types
    
    from all_graph_resources

    group by 1
    having count(distinct resource_type) > 1

)

select * from final 