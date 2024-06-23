-- depends on: {{ source('source_2', 'table_3') }}
select -1234567890 as id, 'blue' as color
union all 
select -1234567890 as id, 'red' as color
