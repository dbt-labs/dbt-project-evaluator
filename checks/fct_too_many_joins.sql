select e.child_unique_id as unique_id,
       count(distinct e.parent_unique_id) as join_count
from {{ info_schema('edges') }} e
join {{ info_schema('models') }} m on m.unique_id = e.child_unique_id
where {{ evaluator_check_in_scope('m') }}
group by e.child_unique_id
having count(distinct e.parent_unique_id) >= {{ var('too_many_joins_threshold', 7) }}
