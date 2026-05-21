-- this model finds cases where a model has a reference to both a model and a source

with direct_model_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where child_resource_type = 'model'
    and distance = 1
    and parent_is_excluded = cast(0 as {{ dbt.type_boolean() }})
    and child_is_excluded = cast(0 as {{ dbt.type_boolean() }})
),

model_and_source_joined as (
    select
        child,
        case
            when (
                sum(case when parent_resource_type = 'model' then 1 else 0 end) > 0
                and sum(case when parent_resource_type = 'source' then 1 else 0 end) > 0
            )
            then cast(1 as {{ dbt.type_boolean() }})
            else cast(0 as {{ dbt.type_boolean() }})
        end as keep_row 
    from direct_model_relationships
    group by child
),

final as (
    select
        direct_model_relationships.parent,
        direct_model_relationships.parent_resource_type,
        direct_model_relationships.child,
        direct_model_relationships.child_resource_type,
        direct_model_relationships.distance
    from direct_model_relationships
    inner join model_and_source_joined
        on direct_model_relationships.child = model_and_source_joined.child
    where model_and_source_joined.keep_row = cast(1 as {{ dbt.type_boolean() }})
)

select * from final

{{ filter_exceptions() }}
order by child