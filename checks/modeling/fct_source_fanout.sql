-- sources selected from by more than one model
select parent_unique_id as unique_id, parent_name as source_name, count(*) as model_children
from {{ evaluator_edges() }}
where parent_resource_type = 'source' and child_resource_type = 'model'
group by all
having model_children > 1
