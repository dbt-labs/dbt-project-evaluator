-- singular test: has no node_unique_id in the information schema, which must not hide fct_missing_primary_key_tests
select * from {{ ref('fct_orders') }} where false
