select s.unique_id, s.name, s.original_file_path
from {{ info_schema('sources') }} s
left join {{ info_schema('edges') }} e on e.parent_unique_id = s.unique_id
where {{ evaluator_check_in_scope('s') }}
group by s.unique_id, s.name, s.original_file_path
having count(e.child_unique_id) = 0
