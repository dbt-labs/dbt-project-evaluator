-- more than one source node pointing at the same database object
select unique_id,
       full_name as source_name,
       lower(concat_ws('.', database_name, schema_name, coalesce(identifier, name))) as source_relation
from {{ evaluator_sources() }}
qualify count(*) over (partition by source_relation) > 1
