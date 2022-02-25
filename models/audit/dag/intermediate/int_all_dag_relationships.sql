-- creates a cte called all_relationships that will either use "with recursive" or loops depending on the DW
{{ recursive_dag() }}

select * from all_relationships
order by parent, distance