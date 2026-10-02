{% set violations %}
-- models with at least `models_fanout_threshold` direct leaf children
-- (a leaf is a model with no children of its own, ignoring tests and the exposures, metrics and
-- saved queries that consume it)
with edges as (select * from {{ evaluator_edges() }})

select parent_unique_id as unique_id, parent_name as name, list(child_name order by child_name) as leaf_children
from edges
where parent_resource_type = 'model'
  and child_resource_type = 'model'
  and child_unique_id not in (select parent_unique_id from edges
                            where child_resource_type not in ('exposure', 'metric', 'saved_query'))
group by all
having len(leaf_children) >= {{ var('models_fanout_threshold') }}
{% endset %}

{{ evaluator_exceptions('fct_model_fanout', violations) }}
