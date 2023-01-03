with 

base_node_relationships as (
    select * from {{ ref('base_node_relationships') }}
),

final as (
    select 
        {{ dbt_utils.generate_surrogate_key(['resource_id', 'direct_parent_id']) }} as unique_id, 
        *
    from base_node_relationships
)

select  * from final