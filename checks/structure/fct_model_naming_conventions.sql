-- models whose name matches none of the prefixes configured for any model type
select unique_id,
       name,
       model_type,
       case model_type
           {%- for model_type in var('model_types') %}
           when '{{ model_type }}' then '{{ evaluator_prefixes(model_type) | join(", ") }}'
           {%- endfor %}
       end as appropriate_prefixes,
       original_file_path
from {{ evaluator_models() }}
where prefix_model_type is null
  and not is_time_spine
