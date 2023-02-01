with 

_base_metric_relationships as (
    select * from {{ ref('base_metric_relationships') }}
),

final as (
    select 
        {{ dbt_utils.generate_surrogate_key(['resource_id', 'direct_parent_id']) }} as unique_id, 
        *
    from _base_metric_relationships
)

{{
    dbt_utils.deduplicate(
        relation='final',
        partition_by='unique_id',
        order_by='is_primary_relationship desc'
    )
}}