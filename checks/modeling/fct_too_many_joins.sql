-- models with at least `too_many_joins_threshold` direct parents
select model.unique_id,
       model.name,
       count(distinct edge.parent_unique_id) as parent_count
from {{ info_schema('models') }} model
join {{ info_schema('edges') }} edge on edge.child_unique_id = model.unique_id
where {{ evaluator_check_in_scope('model') }}
group by model.unique_id, model.name
having count(distinct edge.parent_unique_id) >= {{ var('too_many_joins_threshold') }}
