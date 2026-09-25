with sources as (
    select database_name, schema_name, identifier,
           source_name || '.' || name as resource_name
    from {{ info_schema('sources') }} s
    where {{ evaluator_check_in_scope('s') }}
),
duplicates as (
    select database_name, schema_name, identifier,
           list(resource_name order by resource_name) as source_names,
           count(*) as source_count
    from sources
    group by database_name, schema_name, identifier
    having count(*) > 1
)
select * from duplicates
