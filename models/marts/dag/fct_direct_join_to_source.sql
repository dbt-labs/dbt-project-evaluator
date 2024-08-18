-- this model finds cases where a model has a reference to both a model and a source

with direct_model_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where child_resource_type = 'model'
    and distance = 1
    and not parent_is_excluded
    and not child_is_excluded
),

model_and_source_joined as (
    select
        child,
        case 
            when (
                sum(case when parent_resource_type = 'model' then 1 else 0 end) > 0 
                and sum(case when parent_resource_type = 'source' then 1 else 0 end) > 0
            ) 
            then true
            else false 
        end as keep_row 
    from direct_model_relationships
    group by 1
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
    where model_and_source_joined.keep_row
    order by direct_model_relationships.child
)

select * from final

{{ filter_exceptions() }}