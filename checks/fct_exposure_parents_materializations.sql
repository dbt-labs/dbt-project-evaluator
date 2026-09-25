select parent.resource_type as parent_resource_type,
       case
           when parent.resource_type = 'source'
           then parent.source_name || '.' || parent.name
           else parent.name
       end as parent_resource_name,
       exposure.name as exposure_name,
       model.materialized as parent_model_materialization
from {{ info_schema('exposures') }} exposure
join {{ info_schema('edges') }} edge
  on edge.child_unique_id = exposure.unique_id
join {{ info_schema('graph_nodes') }} parent
  on parent.unique_id = edge.parent_unique_id
left join {{ info_schema('models') }} model
  on model.unique_id = parent.unique_id
where {{ evaluator_check_in_scope('exposure') }}
  and {{ evaluator_check_in_scope('parent') }}
  and (
      parent.resource_type = 'source'
      or (
          parent.resource_type = 'model'
          and model.materialized in ('view', 'ephemeral')
      )
  )
