-- creates a cte called all_relationships that will either use "with recursive" or loops depending on the DW
{{ dbt_project_evaluator.recursive_dag() }}

select * from all_relationships
{#- dbt-sqlserver and dbt-synapse build tables via a temp view, which can't contain ORDER BY -#}
{% if target.type not in ['sqlserver', 'synapse'] %}
order by parent, distance
{% endif %}