-- metricflow_time_spine.sql
{{
    config(
        materialized = 'table',
    )
}}

with days as (

    {{
        dbt_utils.date_spine(
            'day',
            dbt.safe_cast(dbt.current_timestamp(), "date"),
            dbt.dateadd('day', 1, dbt.safe_cast(dbt.current_timestamp(), "date")),
        )
    }}

),

final as (
    select cast(date_day as date) as date_day
    from days
)

select * from final