{{
  config(
    materialized = 'table',
    )
}}

select 1 as id 

-- depends on {{ ref('stg_model_3') }} 

{#
  from {{ ref('stg_model_3') }}   
  union all 
  select
      3 as id
  from my_db.my_schema.my_table
  union all 
  select
      3 as id
  from 'my_db'.'my_schema'.'my_table'
  union all 
  select
      3 as id
  from "my_db"."my_schema"."my_table"
  union all 
  select
      3 as id
  from `my_db`.`my_schema`.`my_table`
  union all 
  select
      3 as id
  from [my_db].[my_schema].[my_table]   
  union all
  select 
      4 as id
  from my_schema.raw_relation_5
  union all
  select 
      4 as id
  from 'my_schema'.'raw_relation_5' 
  union all
  select 
      4 as id
  from "my_schema"."raw_relation_5"
  union all
  select 
      4 as id
  from `my_schema`.`raw_relation_5`
  union all
  select 
      4 as id
  from [my_schema].[raw_relation_5]    
  union all
  select 
      4 as id
  from `raw_relation_1` 
  union all
  select 
      4 as id
  from "raw_relation_2" 
  union all
  select 
      4 as id
  from [raw_relation_3]  
  union all
  select 
      4 as id
  from 'raw_relation_4'
  union all
  select
      4 as id
  from `project-name.dataset_name.table_name`
  union all
  select
      4 as id
  from {{ var("my_table_reference") }}
  union all
  select
      4 as id
  from {{ var('my_table_reference') }}   
  union all
  
  -- the following is SQL commented so it should not be found as a hard coded reference
--   select
--       6 as id
--   from my_db.my_schema.my_table222
  
  select
      5 as id
  from {{ var("my_table_reference", "table_d") }}
  union all
  select
      5 as id
  from {{ var('my_table_reference', 'table_d') }}
  union all
  select 
      5 as id
  from a.b.c
  union all
  select 
      5 as id
  from a.b

#}