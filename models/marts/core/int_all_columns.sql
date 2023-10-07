-- one row for each column in a node or source

select 
    columns.unique_id,
    columns.node_name,
    columns.resource_type,
    columns.file_path,
    columns.database,
    columns.schema,
    columns.package_name,
    columns.alias,
    columns.name,
    columns.description,
    columns.data_type,
    columns.quote
from {{ ref('stg_columns') }} as columns
