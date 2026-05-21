with 

all_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where is_excluded = cast(0 as {{ dbt.type_boolean() }})
),

final as (
    select
        resource_name,
        access,
        is_described,
        total_defined_columns,
        total_described_columns

    from all_resources
    where
        is_public = cast(1 as {{ dbt.type_boolean() }})
        and (
            -- no model level description
            is_described = cast(0 as {{ dbt.type_boolean() }})
            -- not all columns defined have descriptions
            or total_described_columns < total_defined_columns
            -- no columns defined at all
            or total_defined_columns = 0
        )
)

select * from final

{{ filter_exceptions() }}