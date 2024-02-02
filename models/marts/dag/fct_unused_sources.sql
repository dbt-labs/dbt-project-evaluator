-- this model finds cases where a source has no children

with source_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where parent_resource_type = 'source'
    and not parent_is_excluded
    and not child_is_excluded
),

final as (
    select
        parent
    from source_relationships
    group by 1
    having max(distance) = 0
)

select * from final

{{ filter_exceptions() }}