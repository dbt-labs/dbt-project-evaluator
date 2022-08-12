-- this model finds cases where a source is used in multiple direct downstream models
with direct_source_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where distance = 1
    and parent_resource_type = 'source'
    and child_resource_type = 'model'
),

source_fanout as (
    select
        parent,
        {{ dbt_utils.listagg(measure='child', delimiter_text="', '", order_by_clause='order by child') }} as model_children
    from direct_source_relationships
    group by 1
    having count(*) > 1
)

select * from source_fanout

{{ filter_exceptions(this) }}