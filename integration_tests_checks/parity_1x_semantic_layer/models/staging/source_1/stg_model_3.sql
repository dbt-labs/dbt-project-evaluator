-- depends on: {{ source('source_2', 'table_3') }}
select 1 as id, 'blue' as color
union all 
select 1 as id, 'red' as color