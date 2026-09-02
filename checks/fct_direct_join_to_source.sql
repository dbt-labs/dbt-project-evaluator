with parent_types as (
    select e.child_unique_id as unique_id,
           count(*) filter (where s.unique_id is not null) as source_parents,
           count(*) filter (where p.unique_id is not null) as model_parents
    from {{ info_schema('edges') }} e
    join {{ info_schema('models') }} child on child.unique_id = e.child_unique_id
    left join {{ info_schema('sources') }} s on s.unique_id = e.parent_unique_id
    left join {{ info_schema('models') }} p on p.unique_id = e.parent_unique_id
    where {{ evaluator_check_in_scope('child') }}
    group by e.child_unique_id
)
select * from parent_types where source_parents > 0 and model_parents > 0
