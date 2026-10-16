{% snapshot snap_two_sources %}
{{ config(target_schema='snapshots', unique_key='order_id', strategy='check', check_cols='all') }}
select * from {{ source('raw_shop', 'orders') }}, {{ source('raw_shop', 'customers') }}  -- fct_multiple_sources_joined
{% endsnapshot %}
