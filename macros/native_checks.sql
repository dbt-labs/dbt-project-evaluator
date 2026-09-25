{% macro evaluator_check_in_scope(alias) -%}
(
    {{ alias }}.package_name != 'dbt_project_evaluator'
    {% for package in var('exclude_packages', []) %}
    and {{ alias }}.package_name != '{{ package }}'
    {% endfor %}
    {% for path in var('exclude_paths_from_project', []) %}
    and coalesce({{ alias }}.original_file_path, '') not like '%{{ path }}%'
    and {{ alias }}.unique_id not like '%{{ path | replace("/", "") }}%'
    {% endfor %}
)
{%- endmacro %}
