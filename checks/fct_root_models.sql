select m.unique_id, m.name, m.original_file_path
from {{ info_schema('models') }} m
left join {{ info_schema('edges') }} e on e.child_unique_id = m.unique_id
where {{ evaluator_check_in_scope('m') }}
  and not exists (
      select 1 from {{ info_schema('time_spines') }} ts
      where ts.unique_id = m.unique_id
  )
group by m.unique_id, m.name, m.original_file_path
having count(e.parent_unique_id) = 0
