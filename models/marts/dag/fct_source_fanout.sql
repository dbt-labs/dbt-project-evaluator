-- this model finds cases where a source is used in multiple direct downstream models
with direct_source_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where distance = 1
    and parent_resource_type = 'source'
    and child_resource_type = 'model'
    and parent_is_excluded = cast(0 as {{ dbt.type_boolean() }})
    and child_is_excluded = cast(0 as {{ dbt.type_boolean() }})
    {% if target.type not in ['fabric'] %}
    -- we order the CTE so that listagg returns values correctly sorted for some warehouses
    order by child
    {% endif %}
),

source_fanout as (
    select
        parent,
        {{ dbt.listagg(
            measure='child',
            delimiter_text="', '",
            order_by_clause='order by child' if target.type in ['snowflake','redshift','duckdb','trino','fabric'])
        }} as model_children
    from direct_source_relationships
    group by parent
    having count(*) > 1
)

select * from source_fanout

{{ filter_exceptions() }}