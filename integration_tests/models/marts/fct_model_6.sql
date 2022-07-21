{{
  config(
    materialized = 'table',
    )
}}

select 1 as id 
-- depends on: {{ ref('stg_model_3') }}