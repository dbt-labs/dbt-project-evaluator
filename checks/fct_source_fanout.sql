with source_children as (
    select e.parent_unique_id as unique_id,
           count(distinct e.child_unique_id) as model_children
    from {{ info_schema('edges') }} e
    join {{ info_schema('sources') }} s on s.unique_id = e.parent_unique_id
    join {{ info_schema('models') }} m on m.unique_id = e.child_unique_id
    where {{ evaluator_check_in_scope('s') }}
      and {{ evaluator_check_in_scope('m') }}
    group by e.parent_unique_id
)
select * from source_children where model_children > 1
