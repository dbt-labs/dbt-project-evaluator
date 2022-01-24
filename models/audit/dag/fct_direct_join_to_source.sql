-- this model finds cases where a model has a reference to both a model and a source

with direct_model_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where child_type = 'model'
    and distance = 1
),

model_and_source_joined as (
    select
        child,
        sum(case when parent_type = 'model' then 1 else 0 end) as num_model_direct_parents,
        sum(case when parent_type = 'source' then 1 else 0 end) as num_source_direct_parents
    from direct_model_relationships
    group by 1
    having num_model_direct_parents > 0 and num_source_direct_parents > 0
),

final as (
    select 
        direct_model_relationships.*
    from direct_model_relationships
    inner join model_and_source_joined
    on direct_model_relationships.child = model_and_source_joined.child
    order by direct_model_relationships.child
)

select * from final