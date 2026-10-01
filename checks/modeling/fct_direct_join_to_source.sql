{% set violations %}
-- models that read from both a source and another model
select child_unique_id as unique_id,
       child_name as name,
       list(parent_name order by parent_name) filter (where parent_resource_type = 'source') as source_parents,
       list(parent_name order by parent_name) filter (where parent_resource_type = 'model') as model_parents
from {{ evaluator_edges() }}
where child_resource_type = 'model'
group by all
having len(source_parents) > 0 and len(model_parents) > 0
{% endset %}

{{ evaluator_exceptions('fct_direct_join_to_source', violations) }}
