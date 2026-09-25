-- hard-coded relation instead of source(): caught by dbt lint rule DBT05, not by a check
select * from raw_shop.orders
