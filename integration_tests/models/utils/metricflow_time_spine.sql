-- metricflow_time_spine.sql
{% set date_expr = "current_date()" if target.type in ["duckdb"] else dbt.current_timestamp() %}
{{
    config(
        materialized = 'table',
    )
}}

with days as (

    {{
        dbt_utils.date_spine(
            'day',
            date_expr,
            dbt.dateadd('day', 1, date_expr),
        )
    }}

),

final as (
    select cast(date_day as date) as date_day
    from days
)

select * from final