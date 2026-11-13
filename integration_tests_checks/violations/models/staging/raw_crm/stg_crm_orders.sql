select * from {{ source('raw_shop_copy', 'orders') }}  -- in raw_crm dir but reads raw_shop_copy
