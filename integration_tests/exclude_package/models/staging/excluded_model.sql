-- {{ source('fake_source', 'fake_source') }}
select {{ 'toInt32(1)' if target.name in ['clickhouse'] else '1' }} as id
