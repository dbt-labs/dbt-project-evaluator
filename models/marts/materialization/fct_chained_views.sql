with 

chained_views as (
    select
        parent_id,
        parent,
        child_id,
        child,
        distance,
        path as view_path
    from {{ ref('int_all_dag_relationships__chained_views') }}
)

select * from chained_views