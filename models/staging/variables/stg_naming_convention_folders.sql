{% set var_model_types = var('model_types') %}
{% set suffix_model_type = '_directory_name' %}

{% set vars_directories = [] %}

{% for model_type in var_model_types %}
  {% do vars_directories.append(model_type ~ suffix_model_type) %}
{% endfor %}

with vars_directories_table as (
    {{ dbt_project_evaluator.loop_vars(vars_directories) }}
)

select
    var_name as directory_name, 
    {{ dbt.split_part('var_name', "'_'", 1) }} as model_type,
    var_value as directory_name_value
from vars_directories_table