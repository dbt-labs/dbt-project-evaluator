-- models that select from more than one source
select child.unique_id,
       child.name,
       count(distinct source.unique_id) as source_parents
from {{ info_schema('models') }} child
join {{ info_schema('edges') }} edge on edge.child_unique_id = child.unique_id
join {{ info_schema('sources') }} source on source.unique_id = edge.parent_unique_id
where {{ evaluator_check_in_scope('child') }}
  and {{ evaluator_check_in_scope('source') }}
group by child.unique_id, child.name
having count(distinct source.unique_id) > 1
