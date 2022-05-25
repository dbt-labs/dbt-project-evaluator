{% set vars_prefix = ['staging_prefixes','intermediate_prefixes','marts_prefixes', 'other_prefixes'] %}

with vars_prefix_table as (
    {{ loop_vars(vars_prefix) }}
)

select
    var_name as prefix_name, 
    {{ dbt_utils.split_part('var_name', "'_'", 1) }} as model_type,
    var_value as prefix_value
from vars_prefix_table