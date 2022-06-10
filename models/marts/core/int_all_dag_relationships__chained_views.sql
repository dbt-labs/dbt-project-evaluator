-- creates a cte called all_relationships that will either use "with recursive" or loops depending on the DW
{{ dbt_project_evaluator.recursive_dag(filter_views=true) }}

select 
    * 
from all_relationships
where 
    distance <> 0
order by parent, distance