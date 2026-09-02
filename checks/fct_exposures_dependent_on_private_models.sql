select exposure.unique_id as exposure_unique_id,
       exposure.name as exposure_name,
       parent.unique_id as parent_unique_id,
       parent.name as parent_resource_name,
       model.access as parent_access,
       parent.resource_type as parent_resource_type
from {{ info_schema('exposures') }} exposure
join {{ info_schema('edges') }} edge
  on edge.child_unique_id = exposure.unique_id
join {{ info_schema('graph_nodes') }} parent
  on parent.unique_id = edge.parent_unique_id
left join {{ info_schema('models') }} model
  on model.unique_id = parent.unique_id
where {{ evaluator_check_in_scope('exposure') }}
  and {{ evaluator_check_in_scope('parent') }}
  and not (
      parent.resource_type = 'model'
      and model.access = 'public'
  )
