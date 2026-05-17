-- this model finds cases where a source has no children

with source_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where parent_resource_type = 'source'
    and parent_is_excluded = cast(0 as {{ dbt.type_boolean() }})
    and child_is_excluded = cast(0 as {{ dbt.type_boolean() }})
),

final as (
    select
        parent
    from source_relationships
    group by parent
    having max(distance) = 0
)

select * from final

{{ filter_exceptions() }}