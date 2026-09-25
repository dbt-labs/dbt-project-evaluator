select 1 as order_id
from {{ source('raw_shop', 'orders') }}
