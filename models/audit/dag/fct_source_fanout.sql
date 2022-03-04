-- this model finds cases where a source is used in multiple direct downstream models
with direct_source_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where distance = 1
    and parent_resource_type = 'source'
),

source_fanout as (
    select
        parent,
        count(*)
    from direct_source_relationships
    group by 1
    having count(*) > 1
),

final as (
    select 
        direct_source_relationships.*
    from direct_source_relationships
    inner join source_fanout
    on direct_source_relationships.parent = source_fanout.parent
    order by direct_source_relationships.parent
)

select * from final