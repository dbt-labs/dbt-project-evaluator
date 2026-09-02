with typed as (
    select m.unique_id, m.name, m.original_file_path,
           case
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
      and not exists (
      select 1 from {{ info_schema('time_spines') }} ts
      where ts.unique_id = m.unique_id
  )
)
select unique_id, name, model_type, original_file_path
from typed
where (model_type = 'base' and not regexp_matches(name, '^base_'))
   or (model_type = 'staging' and not regexp_matches(name, '^stg_'))
   or (model_type = 'intermediate' and not regexp_matches(name, '^int_'))
   or (model_type = 'marts'
       and not regexp_matches(name, '^fct_')
       and not regexp_matches(name, '^dim_'))
   or (model_type = 'other' and not regexp_matches(name, '^rpt_'))
