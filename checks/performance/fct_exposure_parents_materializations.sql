-- exposures fed directly by a source, or by a view/ephemeral model, instead of a table
select child_unique_id as unique_id,
       child_name as exposure_name,
       parent_resource_type,
       parent_name as parent_resource_name,
       parent_materialized as parent_model_materialization
from {{ evaluator_edges() }}
where child_resource_type = 'exposure'
  and (parent_resource_type = 'source'
       or (parent_resource_type = 'model' and parent_materialized in ('view', 'ephemeral')))
