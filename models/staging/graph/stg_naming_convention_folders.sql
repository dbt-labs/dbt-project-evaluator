{% set vars_prefix = ['staging_folder_name','intermediate_folder_name','marts_folder_name'] %}

with vars_folders_table as (
    {{ loop_vars(vars_prefix) }}
)

select
    var_name as folder_name, 
    {{ dbt_utils.split_part('var_name', "'_'", 1) }} as model_type,
    var_value as folder_name_value
from vars_folders_table