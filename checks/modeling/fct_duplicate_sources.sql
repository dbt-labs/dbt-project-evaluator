-- more than one source node pointing at the same database object
with sources as (
    select source.unique_id,
           source.source_name || '.' || source.name as source_name,
           lower(coalesce(source.database_name, '')) as database_name,
           lower(coalesce(source.schema_name, '')) as schema_name,
           lower(coalesce(source.identifier, source.name)) as identifier
    from {{ info_schema('sources') }} source
    where {{ evaluator_check_in_scope('source') }}
),

duplicated_objects as (
    select database_name, schema_name, identifier
    from sources
    group by database_name, schema_name, identifier
    having count(*) > 1
)

select sources.unique_id,
       sources.source_name,
       sources.database_name || '.' || sources.schema_name || '.' || sources.identifier as source_relation
from sources
join duplicated_objects
  using (database_name, schema_name, identifier)
