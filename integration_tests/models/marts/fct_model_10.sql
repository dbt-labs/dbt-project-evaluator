{{
  config(
    materialized = 'table',
    )
}}

with stg_model_1 as (
    select * from {{ ref('stg_model_1') }}
)

,stg_model_2 as (
    select * from {{ ref('stg_model_2') }}
)

,stg_model_3 as (
    select * from {{ ref('stg_model_3') }}
)

,stg_model_4 as (
    select * from {{ ref('stg_model_4') }}
)

,stg_model_5 as (
    select * from {{ ref('stg_model_5') }}
)

,fct_model_6 as (
    select * from {{ ref('fct_model_6') }}
)

,fct_model_9 as (
    select * from {{ ref('fct_model_9') }}
)

,final as (
    select
        id
    from stg_model_1
    union all
    select
        id
    from stg_model_2
    union all
    select
        id
    from stg_model_3
    union all
    select
        id
    from stg_model_4
    union all
    select
        id
    from stg_model_5
    union all
    select
        id
    from fct_model_6
    union all
    select
        id
    from fct_model_9
    union all
)

select * from final
