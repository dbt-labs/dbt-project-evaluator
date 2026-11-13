{% set violations %}
-- models and snapshots that select from more than one source
select child_unique_id as unique_id, child_name as name, list(parent_name order by parent_name) as source_parents
from {{ evaluator_edges() }}
where parent_resource_type = 'source' and child_resource_type in ('model', 'snapshot')
group by all
having len(source_parents) > 1
{% endset %}

{{ evaluator_exceptions('fct_multiple_sources_joined', violations) }}
