{% set vars_layers = var('list_layers') %}
{% set suffix_layers = '_prefixes' %}

{% set vars_prefix = [] %}

{% for layer in vars_layers %}
  {% do vars_prefix.append(layer ~ suffix_layers) %}
{% endfor %}

with vars_prefix_table as (
    {{ loop_vars(vars_prefix) }}
)

select
    var_name as prefix_name, 
    {{ dbt_utils.split_part('var_name', "'_'", 1) }} as model_type,
    var_value as prefix_value
from vars_prefix_table