select * from {{ ref('int_customers_prepped') }} join {{ ref('stg_customers') }} using (id)  -- rejoining
