with recursive models as (
    select m.*,
           replace(m.original_file_path, chr(92), '/') as normalized_path
    from {{ info_schema('models') }} m
    where {{ evaluator_check_in_scope('m') }}
      and not exists (
          select 1 from {{ info_schema('time_spines') }} ts
          where ts.unique_id = m.unique_id
      )
),
typed as (
    select *,
           case
               {% for model_type in var('model_types', ['base', 'staging', 'intermediate', 'marts', 'other']) %}
               {% set prefixes = var(model_type ~ '_prefixes', []) %}
               {% if prefixes is string %}{% set prefixes = [prefixes] %}{% endif %}
               {% for prefix in prefixes %}
               when starts_with(name, '{{ prefix }}') then '{{ model_type }}'
               {% endfor %}
               {% endfor %}
               {% for model_type in var('model_types', ['base', 'staging', 'intermediate', 'marts', 'other']) if model_type != 'other' %}
               when regexp_matches(
                   normalized_path,
                   '(^|/){{ var(model_type ~ "_folder_name", model_type) }}(/|$)'
               ) then '{{ model_type }}'
               {% endfor %}
               else 'other'
           end as model_type
    from models
),
foldered as (
    select *,
           case
               {% for model_type in var('model_types', ['base', 'staging', 'intermediate', 'marts', 'other']) if model_type != 'other' %}
               when regexp_matches(
                   normalized_path,
                   '(^|/){{ var(model_type ~ "_folder_name", model_type) }}(/|$)'
               ) then '{{ model_type }}'
               {% endfor %}
               else 'other'
           end as folder_model_type,
           regexp_extract(normalized_path, '^(.*)/[^/]+$', 1) as directory_path
    from typed
),
source_paths(source_unique_id, child_unique_id, path) as (
    select source.unique_id,
           edge.child_unique_id,
           [source.unique_id, edge.child_unique_id]
    from {{ info_schema('sources') }} source
    join {{ info_schema('edges') }} edge
      on edge.parent_unique_id = source.unique_id
    where {{ evaluator_check_in_scope('source') }}

    union all

    select source_paths.source_unique_id,
           edge.child_unique_id,
           list_append(source_paths.path, edge.child_unique_id)
    from source_paths
    join {{ info_schema('edges') }} edge
      on edge.parent_unique_id = source_paths.child_unique_id
    where not list_contains(source_paths.path, edge.child_unique_id)
),
staging_source_violations as (
    select distinct
           child.unique_id,
           child.name,
           child.model_type,
           child.original_file_path as current_file_path,
           'models/{{ var("staging_folder_name", "staging") }}/'
           || source.source_name || '/'
           || regexp_extract(child.normalized_path, '[^/]+$', 0)
           as change_file_path_to
    from foldered child
    join source_paths path on path.child_unique_id = child.unique_id
    join {{ info_schema('sources') }} source
      on source.unique_id = path.source_unique_id
    where child.model_type = 'staging'
      and child.directory_path not like '%' || source.source_name || '%'
),
folder_violations as (
    select unique_id, name, model_type,
           original_file_path as current_file_path,
           'models/.../'
           || case model_type
               {% for model_type in var('model_types', ['base', 'staging', 'intermediate', 'marts', 'other']) if model_type != 'other' %}
               when '{{ model_type }}' then '{{ var(model_type ~ "_folder_name", model_type) }}'
               {% endfor %}
               else model_type
              end
           || '/.../'
           || regexp_extract(normalized_path, '[^/]+$', 0)
           as change_file_path_to
    from foldered
    where model_type != 'other'
      and model_type != folder_model_type
)
select * from staging_source_violations
union all by name
select * from folder_violations
