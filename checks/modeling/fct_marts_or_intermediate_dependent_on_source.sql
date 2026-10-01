{% set violations %}
-- marts and intermediate models that select directly from a source
select child_unique_id as unique_id, child_name as name, child_model_type as model_type, parent_name as source_name
from {{ evaluator_edges() }}
where parent_resource_type = 'source'
  and child_model_type in ('marts', 'intermediate')
{% endset %}

{{ evaluator_exceptions('fct_marts_or_intermediate_dependent_on_source', violations) }}
