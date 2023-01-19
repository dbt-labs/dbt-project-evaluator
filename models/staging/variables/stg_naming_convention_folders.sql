{% set var_model_types = var('model_types') %}
{% set suffix_folder = '_folder_name' %}

{% set vars_folders = [] %}

{% for model_type in var_model_types %}
  {% do vars_folders.append(model_type ~ suffix_folder) %}
{% endfor %}

with vars_folders_table as (
    {{ dbt_project_evaluator.loop_vars(vars_folders) }}
)

select
    var_name as folder_name, 
    {{ dbt.replace('var_name', wrap_string_with_quotes(suffix_folder), "''") }} as model_type,
    var_value as folder_name_value
from vars_folders_table
