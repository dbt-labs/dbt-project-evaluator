-- one row for each column in a node or source

with

stg_columns as (

    select
        node_unique_id,
        name,
        description,
        data_type,
        quote

    from {{ ref('stg_columns') }}

),

stg_nodes as (

    select
        unique_id,
        name,
        resource_type,
        file_path,
        is_enabled,
        database,
        schema,
        package_name,
        alias

    from {{ ref('stg_nodes') }}

),

final as (

    select
        stg_nodes.unique_id as node_unique_id,
        stg_nodes.name as node_name,
        stg_nodes.resource_type as node_resource_type,
        stg_nodes.file_path as node_file_path,
        stg_nodes.is_enabled as node_is_enabled,
        stg_nodes.database as node_database,
        stg_nodes.schema as node_schema,
        stg_nodes.package_name as node_package_name,
        stg_nodes.alias as node_alias,
        stg_columns.name as name,
        stg_columns.description as description,
        stg_columns.data_type as data_type,
        stg_columns.quote as quote

    from stg_columns

    right join stg_nodes
        on stg_nodes.unique_id = stg_columns.node_unique_id

)

select * from final
