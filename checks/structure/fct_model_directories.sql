-- models outside the directory their model type calls for:
--   * staging models must sit in a directory named after each source they (transitively) read from
--   * a model whose prefix says one type but whose deepest configured folder says another
with recursive
models as (select * from {{ evaluator_models() }} where not is_time_spine),
edges as (select * from {{ evaluator_edges() }}),

-- every (staging model, upstream node) pair
staging_ancestors(staging_unique_id, ancestor_unique_id) as (
    select child_unique_id, parent_unique_id from edges where child_model_type = 'staging'
    union
    select staging_ancestors.staging_unique_id, edges.parent_unique_id
    from staging_ancestors
    join edges on edges.child_unique_id = staging_ancestors.ancestor_unique_id
)

select distinct models.unique_id, models.name, models.model_type,
       models.original_file_path as current_file_path,
       'models/{{ var("staging_folder_name") }}/' || source.source_name || '/' || models.file_name as change_file_path_to
from models
join staging_ancestors on staging_ancestors.staging_unique_id = models.unique_id
join {{ evaluator_sources() }} source on source.unique_id = staging_ancestors.ancestor_unique_id
where models.directory_path not like '%' || source.source_name || '%'

union all

select unique_id, name, model_type,
       original_file_path,
       'models/.../'
           || case model_type
               {%- for model_type in var('model_types') if var(model_type ~ '_folder_name', none) %}
               when '{{ model_type }}' then '{{ var(model_type ~ "_folder_name") }}'
               {%- endfor %}
               else '<no folder configured for ' || model_type || '>'
              end
           || '/.../' || file_name
from models
where model_type != folder_model_type
