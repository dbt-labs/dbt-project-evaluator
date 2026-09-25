{#
    Helpers shared by the native checks in checks/.
    Checks render at parse time and run in DuckDB against the dbt information schema,
    so everything here must produce DuckDB SQL.
#}

{# true when the resource aliased as `alias` is not excluded by package or path #}
{% macro evaluator_check_in_scope(alias) -%}
(
    coalesce({{ alias }}.package_name, '') != 'dbt_project_evaluator'
    {%- for package in var('exclude_packages', []) %}
    and coalesce({{ alias }}.package_name, '') != '{{ package }}'
    {%- endfor %}
    {%- for path in var('exclude_paths_from_project', []) %}
    and coalesce({{ alias }}.original_file_path, '') not like '%{{ path }}%'
    and {{ alias }}.unique_id not like '%{{ path | replace("/", "") }}%'
    {%- endfor %}
)
{%- endmacro %}


{#
    Every DAG participant with the attributes the checks need.
    `dag_nodes` only carries unique_id and resource_type, so names, packages, paths and
    materializations come from the per-resource views.
#}
{% macro evaluator_nodes() -%}
(
    select dag_node.unique_id,
           dag_node.resource_type,
           attributes.name,
           attributes.package_name,
           attributes.original_file_path,
           attributes.materialized,
           attributes.version,
           attributes.source_name
    from {{ info_schema('dag_nodes') }} dag_node
    left join (
        {%- for view in ['models', 'seeds', 'snapshots', 'functions'] %}
        select unique_id, name, package_name, original_file_path, materialized,
               nullif(cast(version as varchar), 'null') as version, cast(null as varchar) as source_name
        from {{ info_schema(view) }}
        union all
        {%- endfor %}
        select unique_id, name, package_name, original_file_path, materialized,
               cast(null as varchar), source_name
        from {{ info_schema('sources') }}
        union all
        select unique_id, name, package_name, original_file_path, materialized,
               cast(null as varchar), cast(null as varchar)
        from {{ info_schema('data_tests') }}
        {%- for view in ['exposures', 'metrics', 'saved_queries', 'unit_tests'] %}
        union all
        select unique_id, name, package_name, original_file_path, cast(null as varchar),
               cast(null as varchar), cast(null as varchar)
        from {{ info_schema(view) }}
        {%- endfor %}
    ) attributes on attributes.unique_id = dag_node.unique_id
)
{%- endmacro %}


{# directory portion of a file path, normalized to forward slashes #}
{% macro evaluator_directory(path_expr) -%}
regexp_extract(replace({{ path_expr }}, chr(92), '/'), '^(.*)/[^/]+$', 1)
{%- endmacro %}


{# file name portion of a file path #}
{% macro evaluator_file_name(path_expr) -%}
regexp_extract(replace({{ path_expr }}, chr(92), '/'), '[^/]+$', 0)
{%- endmacro %}


{# list of prefixes configured for a model type (the var may be a string or a list) #}
{% macro evaluator_prefixes(model_type) -%}
    {%- set prefixes = var(model_type ~ '_prefixes', []) -%}
    {%- if prefixes is string -%}{%- set prefixes = [prefixes] -%}{%- endif -%}
    {{ return(prefixes) }}
{%- endmacro %}


{# model types that have a configured <model_type>_folder_name #}
{% macro evaluator_foldered_model_types() -%}
    {%- set foldered = [] -%}
    {%- for model_type in var('model_types') -%}
        {%- if var(model_type ~ '_folder_name', none) -%}
            {%- do foldered.append(model_type) -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(foldered) }}
{%- endmacro %}


{# model type implied by the name prefix, or null #}
{% macro evaluator_prefix_model_type(alias) -%}
case
    {%- for model_type in var('model_types') %}
    {%- for prefix in evaluator_prefixes(model_type) %}
    when starts_with({{ alias }}.name, '{{ prefix }}') then '{{ model_type }}'
    {%- endfor %}
    {%- endfor %}
end
{%- endmacro %}


{#
    model type implied by the directory, or null.
    When several configured folders appear in the path, the deepest one wins.
#}
{% macro evaluator_folder_model_type(alias) -%}
{%- set foldered = evaluator_foldered_model_types() -%}
{%- set dir = "('/' || " ~ evaluator_directory(alias ~ ".original_file_path") ~ " || '/')" -%}
{%- if foldered | length == 0 -%}
cast(null as varchar)
{%- else -%}
case
    {%- for model_type in foldered %}
    when strpos({{ dir }}, '/{{ var(model_type ~ "_folder_name") }}/') > 0
     and strpos({{ dir }}, '/{{ var(model_type ~ "_folder_name") }}/') = greatest(
        {%- for other in foldered %}
        strpos({{ dir }}, '/{{ var(other ~ "_folder_name") }}/'){% if not loop.last %},{% endif %}
        {%- endfor %}
     ) then '{{ model_type }}'
    {%- endfor %}
end
{%- endif -%}
{%- endmacro %}


{# model type: prefix first, then folder, then 'other' (matches the legacy int_all_graph_resources logic) #}
{% macro evaluator_model_type(alias) -%}
coalesce({{ evaluator_prefix_model_type(alias) }}, {{ evaluator_folder_model_type(alias) }}, 'other')
{%- endmacro %}


{# true when the model aliased as `alias` is a semantic-layer time spine #}
{% macro evaluator_is_time_spine(alias) -%}
exists (
    select 1 from {{ info_schema('time_spines') }} time_spine
    where time_spine.unique_id = {{ alias }}.unique_id
)
{%- endmacro %}


{# true when a description column holds real text #}
{% macro evaluator_is_documented(column) -%}
(nullif(trim({{ column }}), '') is not null)
{%- endmacro %}
