with

relationships as (

    select * from {{ ref('int_all_dag_relationships') }}

),

resources_to_filter as (

    select distinct resource_id
    from {{ ref('int_all_graph_resources') }}
    where package_name = 'dbt_project_evaluator'

),

final as (
    select *
    from relationships
    where
        not exists (
            select 1
            from resources_to_filter
            where
                resources_to_filter.resource_id = relationships.parent_id or
                resources_to_filter.resource_id = relationships.child_id
        )
)

select * from final
