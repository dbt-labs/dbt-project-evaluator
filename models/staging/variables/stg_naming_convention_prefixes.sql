{% set var_model_types = var('model_types') %}
{% set suffix_model_type = '_prefixes' %}

{% set vars_prefix = [] %}

{% for model_type in var_model_types %}
  {% do vars_prefix.append(model_type ~ suffix_model_type) %}
{% endfor %}

with vars_prefix_table as (
    {{ dbt_project_evaluator.loop_vars(vars_prefix) }}
),

parsed as (

select
    var_name as prefix_name, 
    {{ dbt_utils.split_part('var_name', "'_'", 1) }} as model_type,
    var_value as prefix_value
from vars_prefix_table

),

final as (

    select
        {{ dbt_utils.surrogate_key(['model_type', 'prefix_value']) }} as unique_id,
        *
    from parsed

)

select * from final