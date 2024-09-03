with all_dag_relationships as (
    select
        *
    from {{ ref('int_all_dag_relationships') }}
    where not child_is_excluded
    and child_resource_type = 'model'
),

final as (
    select
        child as resource_name,
        child_file_path as file_path,
        cast(count(distinct parent) as {{ dbt.type_int() }}) as join_count
    from all_dag_relationships
    where distance = 1
    group by 1, 2
    having count(distinct parent) >= {{ var('too_many_joins_threshold') }}
)

select * from final

{{ filter_exceptions() }}
