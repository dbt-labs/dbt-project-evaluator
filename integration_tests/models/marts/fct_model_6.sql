{{
  config(
    materialized = 'table',
    )
}}

select 1 as id 
-- from {{ ref('stg_model_3') }}

-- union all 
-- select
--     3 as id
-- from my_db.my_schema.my_table
-- union all 
-- select
--     3 as id
-- from 'my_db'.'my_schema'.'my_table'
-- union all 
-- select
--     3 as id
-- from "my_db"."my_schema"."my_table"
-- union all 
-- select
--     3 as id
-- from `my_db`.`my_schema`.`my_table`
-- union all 
-- select
--     3 as id
-- from [my_db].[my_schema].[my_table]

-- union all
-- select 
--     4 as id
-- from my_schema.raw_relation_5
-- union all
-- select 
--     4 as id
-- from 'my_schema'.'raw_relation_5' 
-- union all
-- select 
--     4 as id
-- from "my_schema"."raw_relation_5"
-- union all
-- select 
--     4 as id
-- from `my_schema`.`raw_relation_5`
-- union all
-- select 
--     4 as id
-- from [my_schema].[raw_relation_5] 


-- union all
-- select 
--     4 as id
-- from `raw_relation_1` 
-- union all
-- select 
--     4 as id
-- from "raw_relation_2" 
-- union all
-- select 
--     4 as id
-- from [raw_relation_3]  
-- union all
-- select 
--     4 as id
-- from 'raw_relation_4' 

-- union all
-- select
--     4 as id
-- from {{ var("my_table_reference") }}
-- union all
-- select
--     4 as id
-- from {{ var('my_table_reference') }}


-- union all
-- select
--     5 as id
-- from {{ var("my_table_reference", "table_d") }}
-- union all
-- select
--     5 as id
-- from {{ var('my_table_reference', 'table_d') }}
-- select
--     7 as id
-- from {{ var('my_table_reference', 'table_d') }}