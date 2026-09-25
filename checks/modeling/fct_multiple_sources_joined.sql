-- models that select from more than one source
select child_unique_id as unique_id, child_name as name, count(*) as source_parents
from {{ evaluator_edges() }}
where parent_resource_type = 'source' and child_resource_type = 'model'
group by all
having source_parents > 1
