-- depends on: {{ source('source_2', 'table_3') }}
select 'a' as id, 'blue' as color
union all 
select 'a' as id, 'red' as color
