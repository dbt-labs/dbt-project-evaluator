-- depends on: {{ source('source_2', 'table_3') }}
select {{ 'toInt32(1)' if target.name in ['clickhouse'] else '1' }} as id, 'blue' as color
union all 
select {{ 'toInt32(1)' if target.name in ['clickhouse'] else '1' }} as id, 'red' as color
