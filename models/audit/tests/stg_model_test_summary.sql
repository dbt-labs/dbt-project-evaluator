with 

models as (
    select * from {{ ref('base__nodes') }}
    where 
        is_enabled
        and resource_type = 'model'
),

test_relationships as (
    select * from {{ ref('base__node_relationships') }}
    where resource_type = 'test'
),

agg_relationships as (
    
    select 
        direct_parent_id, 
        count(distinct node_id) as tests_per_model 
    
    from test_relationships
    group by 1
),

final as (
    select 
        models.unique_id, 
        coalesce(agg_relationships.tests_per_model, 0) as tests_per_model
    from models
    left join agg_relationships
        on models.unique_id = agg_relationships.direct_parent_id
)

select * from final

