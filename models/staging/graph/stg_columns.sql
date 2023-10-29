with

final as (

    {{ dbt_utils.union_relations([
        ref('base_node_columns'),
        ref('base_source_columns')
    ])}}
)

select distinct * from final
