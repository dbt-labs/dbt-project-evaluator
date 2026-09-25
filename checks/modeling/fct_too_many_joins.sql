-- models with at least `too_many_joins_threshold` direct parents
select child_unique_id as unique_id, child_name as name, count(*) as parent_count
from {{ evaluator_edges() }}
where child_resource_type = 'model'
group by all
having parent_count >= {{ var('too_many_joins_threshold') }}
