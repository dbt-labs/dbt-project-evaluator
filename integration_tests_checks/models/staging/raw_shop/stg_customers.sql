select * from {{ source('raw_shop', 'customers') }}
