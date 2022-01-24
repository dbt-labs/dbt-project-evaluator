-- this model finds cases where a model has 0 direct parents, likely due to a lack of source or ref function
-- TO DO: 
    -- decide how seeds are handled in these dag tests, seeds are in the base__nodes model where resource_type = 'seed' 

with model_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where child_type = 'model'
),

final as (
    select
        child
    from model_relationships
    group by 1
    having max(distance) = 0
)

select * from final

-- TO DO: Which query is better?

-- with direct_relationships as ( 
--     select  
--         *
--     from {{ ref('stg_direct_relationships') }}  
-- ),
-- 
-- final as (
--     select distinct 
--         node,
--         resource_type,
--         direct_parent_id
--     from direct_relationships
--     where resource_type = 'model'
--     and direct_parent_id is NULL
-- )
-- 
-- select * from final