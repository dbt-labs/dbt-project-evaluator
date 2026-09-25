-- exposures whose direct parents are anything other than public models
select child_unique_id as unique_id,
       child_name as exposure_name,
       parent_unique_id,
       parent_name as parent_resource_name,
       parent_resource_type,
       parent_access
from {{ evaluator_edges() }}
where child_resource_type = 'exposure'
  and not (parent_resource_type = 'model' and parent_access = 'public')
