-- models whose name does not start with any prefix configured for its model type.
-- A model whose name matches a configured prefix takes that prefix's type, so only models
-- matching no prefix at all can fail; their type then comes from their folder (or 'other').
with models as (
    select model.unique_id,
           model.name,
           model.original_file_path,
           {{ evaluator_prefix_model_type('model') }} as prefix_model_type,
           {{ evaluator_model_type('model') }} as model_type
    from {{ info_schema('models') }} model
    where {{ evaluator_check_in_scope('model') }}
      and not {{ evaluator_is_time_spine('model') }}
)

select unique_id,
       name,
       model_type,
       case model_type
           {%- for model_type in var('model_types') %}
           when '{{ model_type }}' then '{{ evaluator_prefixes(model_type) | join(", ") }}'
           {%- endfor %}
       end as appropriate_prefixes,
       original_file_path
from models
where prefix_model_type is null
