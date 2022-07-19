with

final as (

    select *
    from {{ ref('int_all_graph_resources') }}
    where package_name <> 'dbt_project_evaluator'

)

select * from final
