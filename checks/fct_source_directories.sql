with sources as (
    select unique_id, source_name, original_file_path,
           regexp_extract(
               replace(original_file_path, chr(92), '/'),
               '^(.*)/[^/]+$',
               1
           ) as directory_path
    from {{ info_schema('sources') }} s
    where {{ evaluator_check_in_scope('s') }}
)
select unique_id, source_name, original_file_path as current_file_path,
       'models/{{ var("staging_folder_name", "staging") }}/'
       || source_name || '/'
       || regexp_extract(replace(original_file_path, chr(92), '/'), '[^/]+$', 0)
       as change_file_path_to
from sources
where directory_path not like '%' || source_name || '%'
