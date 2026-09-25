-- sources whose YAML is not in a directory named after the source
select unique_id,
       full_name as source_name,
       original_file_path as current_file_path,
       'models/{{ var("staging_folder_name") }}/' || source_name || '/' || file_name as change_file_path_to
from {{ evaluator_sources() }}
where directory_path not like '%' || source_name || '%'
