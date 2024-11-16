{% macro set_is_excluded(resource, resource_type) %}
    {{ return(adapter.dispatch('set_is_excluded', 'dbt_project_evaluator')(resource, resource_type)) }}
{% endmacro %}

{% macro default__set_is_excluded(resource, resource_type) %}

    {% set re = modules.re %}
    {%- set ns = namespace(exclude=false) -%}

    {% if resource_type == 'node' %}
        {%- set resource_path = resource.original_file_path | replace("\\","\\\\") -%}
    {% elif resource_type == 'source' %}
        {%- set resource_path = resource.original_file_path | replace("\\","\\\\") ~ ":" ~ resource.fqn[-2] ~ "." ~ resource.fqn[-1] -%}
    {% else %}
        {{ exceptions.raise_compiler_error(
            "`set_is_excluded()` macro does not support resource type: " ~ resource_type
        ) }}
    {% endif %}
    

    {#- we duplicate the exclusion list to account for windows directory patterns -#}
    {%- set exclude_all_os_paths_from_project = [] -%}

    {%- for exclude_paths_pattern in var('exclude_paths_from_project',[]) -%}
        {%- set windows_path_pattern = exclude_paths_pattern | replace("/", "\\\\\\\\") -%}
        {%- do exclude_all_os_paths_from_project.extend([exclude_paths_pattern, windows_path_pattern]) -%}
    {%- endfor -%}

    {#- we exclude the resource if it is from the current project and matches the pattern -#}
    {%- for exclude_paths_pattern in exclude_all_os_paths_from_project -%}
        {%- set matched_path = re.search(exclude_paths_pattern, resource_path, re.IGNORECASE) -%}
        {%- if matched_path and resource.package_name == project_name %}
            {% set ns.exclude = true %}
        {%- endif -%}
    {%- endfor -%}

    {#- we exclude the resource if the package if it is listed in `exclude_packages` or if it is "all" -#}
    {%- if (
        resource.package_name != project_name) 
        and (resource.package_name in  var('exclude_packages',[]) or 'all' in var('exclude_packages',[])) 
    -%}
        {% set ns.exclude = true %}
    {%- endif -%}

    {{ return(ns.exclude) }}

{% endmacro %}
