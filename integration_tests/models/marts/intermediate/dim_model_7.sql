
{{
    config(
        materialized = 'table',
    )
}}

select * from {{ ref('stg_model_4') }}
-- {{ ref('int_model_5') }}