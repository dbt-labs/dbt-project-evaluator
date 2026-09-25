-- exposures whose direct parents are anything other than public models
select exposure.unique_id,
       exposure.name as exposure_name,
       parent.unique_id as parent_unique_id,
       parent.name as parent_resource_name,
       parent.resource_type as parent_resource_type,
       model.access as parent_access
from {{ info_schema('exposures') }} exposure
join {{ info_schema('edges') }} edge on edge.child_unique_id = exposure.unique_id
join {{ evaluator_nodes() }} parent on parent.unique_id = edge.parent_unique_id
left join {{ info_schema('models') }} model on model.unique_id = parent.unique_id
where {{ evaluator_check_in_scope('exposure') }}
  and {{ evaluator_check_in_scope('parent') }}
  and not (parent.resource_type = 'model' and coalesce(model.access, '') = 'public')
