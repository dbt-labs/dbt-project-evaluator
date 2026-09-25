-- sources selected from by more than one model
select source.unique_id,
       source.source_name || '.' || source.name as source_name,
       count(distinct child.unique_id) as model_children
from {{ info_schema('sources') }} source
join {{ info_schema('edges') }} edge on edge.parent_unique_id = source.unique_id
join {{ info_schema('models') }} child on child.unique_id = edge.child_unique_id
where {{ evaluator_check_in_scope('source') }}
  and {{ evaluator_check_in_scope('child') }}
group by source.unique_id, source.source_name, source.name
having count(distinct child.unique_id) > 1
