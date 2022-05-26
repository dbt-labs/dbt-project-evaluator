{% set vars_layers = var('list_layers') %}
{% set suffix_layers = '_folder_name' %}

{% set vars_folders = [] %}

{% for layer in vars_layers %}
  {% do vars_folders.append(layer ~ suffix_layers) %}
{% endfor %}

with vars_folders_table as (
    {{ loop_vars(vars_folders) }}
)

select
    var_name as folder_name, 
    {{ dbt_utils.split_part('var_name', "'_'", 1) }} as model_type,
    var_value as folder_name_value
from vars_folders_table