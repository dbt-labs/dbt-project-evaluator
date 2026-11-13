select * from {{ source('raw_shop', 'orders') }}
