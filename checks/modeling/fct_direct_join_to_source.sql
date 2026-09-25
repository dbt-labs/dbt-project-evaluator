-- models that read from both a source and another model
select child_unique_id as unique_id,
       child_name as name,
       count(*) filter (where parent_resource_type = 'source') as source_parents,
       count(*) filter (where parent_resource_type = 'model') as model_parents
from {{ evaluator_edges() }}
where child_resource_type = 'model'
group by all
having source_parents > 0 and model_parents > 0
