{{
  config(
    materialized = 'table',
    )
}}

select 1 from {{ ref('stg_model_3') }}