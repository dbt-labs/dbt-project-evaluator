with all_dag_relationships as (
    select
        *
    from {{ ref('int_all_dag_relationships') }}
    where not child_is_excluded
),

final as (
    select
        child as resource_name,
        child_resource_type as resource_type,
        child_file_path as file_path,
        count(distinct parent) as join_count
    from all_dag_relationships
    where distance = 1
    and child_model_type in ('marts')
    group by
        child,
        child_resource_type,
        child_file_path
    having count(distinct parent) >= {{ var('too_many_joins_threshold') }}
)

select * from final

--  {{ filter_exceptions(model.name) }}
