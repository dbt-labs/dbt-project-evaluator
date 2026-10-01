-- this needs to be valid SQL for the fake test to run
-- depends on: {{ source('source_1', 'table_1') }}
select 1 as id 
union all 
select 2 as id