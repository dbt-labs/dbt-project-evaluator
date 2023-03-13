with 

all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
    where 
        resource_type != 'test'
        and resource_yml_file_path is not null
),

check_naming_convention as (

    select 
        resource_name, 
        resource_type, 
        resource_yml_file_path,
        resource_yml_file_name,
        {{ dbt.position("'_'", 'resource_yml_file_name') }} = 1 as has_leading_underscore,
        {{ dbt.position(dbt.concat(["resource_type", "'s.yml'"]), 'resource_yml_file_name') }} > 0 as has_plural_resource_name,
        {{ dbt.concat([
            "'_'",
            "resource_type",
            "'s.yml'"
        ]) }} as valid_filename_option_1,
        {{ dbt.concat([
            "'_'",
            dbt.split_part('resource_yml_file_path', "'" ~ get_directory_pattern() ~ "'", -2),
            "'__'",
            "resource_type",
            "'s.yml'"
        ]) }} as valid_filename_option_2
        
    
    from all_graph_resources

)

select * from check_naming_convention
where 
    resource_yml_file_name != valid_filename_option_1
    and resource_yml_file_name != valid_filename_option_2
