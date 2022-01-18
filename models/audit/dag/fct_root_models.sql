-- this model finds cases where a model has 0 direct parents, likely due to a lack of source or ref function
-- TO DO: What are seeds classified as?
with direct_relationships as ( 
    select  
        *
    from {{ ref('stg_direct_relationships') }}  
),

final as (
    select distinct 
        node,
        resource_type,
        direct_parent_id
    from direct_relationships
    where resource_type = 'model'
    and direct_parent_id is NULL
)

select * from final