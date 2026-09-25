with typed as (
    select m.unique_id, case
            when regexp_matches(m.name, '^base_') then 'base'
            when regexp_matches(m.name, '^stg_') then 'staging'
            when regexp_matches(m.name, '^int_') then 'intermediate'
            when regexp_matches(m.name, '^(fct|dim)_') then 'marts'
            when m.original_file_path like '%/base/%' then 'base'
            when m.original_file_path like '%/staging/%' then 'staging'
            when m.original_file_path like '%/intermediate/%' then 'intermediate'
            when m.original_file_path like '%/marts/%' then 'marts'
            else 'other'
        end as model_type
    from {{ info_schema('models') }} m
    where {{ evaluator_check_in_scope('m') }}
)
select child.unique_id, e.parent_unique_id, child.model_type
from {{ info_schema('edges') }} e
join {{ info_schema('sources') }} source on source.unique_id = e.parent_unique_id
join typed child on child.unique_id = e.child_unique_id
where {{ evaluator_check_in_scope('source') }}
  and child.model_type in ('marts', 'intermediate')
