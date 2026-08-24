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
select child.unique_id, e.parent_unique_id, parent.model_type as parent_model_type
from {{ info_schema('edges') }} e
join typed parent on parent.unique_id = e.parent_unique_id
join typed child on child.unique_id = e.child_unique_id
where child.model_type = 'staging'
  and parent.model_type in ('marts', 'intermediate')
