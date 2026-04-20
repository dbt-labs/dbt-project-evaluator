
{{
    config(
        materialized = 'table',
    )
}}

-- {{ ref('int_model_5') }}
select
    *,
    cast('2024-01-01' as date) as date_day
from {{ ref('stg_model_4') }}
