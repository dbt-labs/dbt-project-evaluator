
{{
    config(
        materialized = 'table',
    )
}}

-- {{ ref('int_model_5') }}
select * from {{ ref('stg_model_4') }}
