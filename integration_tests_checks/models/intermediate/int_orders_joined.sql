select * from {{ ref('stg_orders') }} join {{ source('raw_shop', 'orders') }} using (id)  -- direct join to source
