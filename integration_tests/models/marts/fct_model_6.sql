{{
  config(
    materialized = 'table',
    )
}}

select * from {{ ref('stg_model_3') }}