{% set violations %}
-- sources selected from by more than one model
select parent_unique_id as unique_id, parent_name as source_name, list(child_name order by child_name) as model_children
from {{ evaluator_edges() }}
where parent_resource_type = 'source' and child_resource_type = 'model'
group by all
having len(model_children) > 1
{% endset %}

{{ evaluator_exceptions('fct_source_fanout', violations) }}
