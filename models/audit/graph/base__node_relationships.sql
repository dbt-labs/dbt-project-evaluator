with relationships as (

    {{
        get_node_relationships()
    }}

),


final as (
    select 
        {{ dbt_utils.surrogate_key(['node_id', 'direct_parent_id']) }} as unique_id, 
        *
    from relationships
)

select distinct * from final