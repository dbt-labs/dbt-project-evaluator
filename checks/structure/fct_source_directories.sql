-- sources whose YAML is not in a directory named after the source
select source.unique_id,
       source.source_name || '.' || source.name as source_name,
       source.original_file_path as current_file_path,
       'models/{{ var("staging_folder_name") }}/' || source.source_name || '/'
           || {{ evaluator_file_name('source.original_file_path') }} as change_file_path_to
from {{ info_schema('sources') }} source
where {{ evaluator_check_in_scope('source') }}
  and {{ evaluator_directory('source.original_file_path') }} not like '%' || source.source_name || '%'
