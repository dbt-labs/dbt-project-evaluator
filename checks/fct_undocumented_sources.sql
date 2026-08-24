select source_name
from {{ info_schema('sources') }} s
where {{ evaluator_check_in_scope('s') }}
group by source_name
having count(*) filter (
    where nullif(trim(source_description), '') is null
) > 0
