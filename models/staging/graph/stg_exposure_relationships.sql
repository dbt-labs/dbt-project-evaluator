with 

_base_exposure_relationships as (
    select * from {{ ref('base_exposure_relationships') }}
),

final as (
    select 
        {{ dbt_utils.generate_surrogate_key(['resource_id', 'direct_parent_id']) }} as unique_id, 
        *
    from _base_exposure_relationships
)

select distinct * from final