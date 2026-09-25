-- models that are not in the directory their model type calls for:
--   * staging models must sit in a directory named after each source they (transitively) read from
--   * any model whose prefix says one type but whose closest configured folder says another
with recursive models as (
    select model.unique_id,
           model.name,
           model.original_file_path,
           {{ evaluator_directory('model.original_file_path') }} as directory_path,
           {{ evaluator_file_name('model.original_file_path') }} as file_name,
           {{ evaluator_model_type('model') }} as model_type,
           {{ evaluator_folder_model_type('model') }} as folder_model_type
    from {{ info_schema('models') }} model
    where {{ evaluator_check_in_scope('model') }}
      and not {{ evaluator_is_time_spine('model') }}
),

-- every (staging model, upstream node) pair; `union` dedupes so the walk terminates
staging_ancestors(staging_unique_id, ancestor_unique_id) as (
    select models.unique_id, edge.parent_unique_id
    from models
    join {{ info_schema('edges') }} edge on edge.child_unique_id = models.unique_id
    where models.model_type = 'staging'

    union

    select staging_ancestors.staging_unique_id, edge.parent_unique_id
    from staging_ancestors
    join {{ info_schema('edges') }} edge on edge.child_unique_id = staging_ancestors.ancestor_unique_id
),

staging_violations as (
    select distinct
           models.unique_id,
           models.name,
           models.model_type,
           models.original_file_path as current_file_path,
           'models/{{ var("staging_folder_name") }}/' || source.source_name || '/' || models.file_name
               as change_file_path_to
    from models
    join staging_ancestors on staging_ancestors.staging_unique_id = models.unique_id
    join {{ info_schema('sources') }} source on source.unique_id = staging_ancestors.ancestor_unique_id
    where {{ evaluator_check_in_scope('source') }}
      and models.directory_path not like '%' || source.source_name || '%'
),

folder_violations as (
    select unique_id,
           name,
           model_type,
           original_file_path as current_file_path,
           'models/.../'
               || case model_type
                   {%- for model_type in evaluator_foldered_model_types() %}
                   when '{{ model_type }}' then '{{ var(model_type ~ "_folder_name") }}'
                   {%- endfor %}
                   else '<no folder configured for ' || model_type || '>'
                  end
               || '/.../' || file_name
               as change_file_path_to
    from models
    where folder_model_type is not null
      and model_type != folder_model_type
)

select * from staging_violations
union all
select * from folder_violations
