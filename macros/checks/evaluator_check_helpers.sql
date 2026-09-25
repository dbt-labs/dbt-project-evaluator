{#
    Shared relations for the checks in checks/. Checks render at parse time and run in
    DuckDB against the dbt information schema, so everything here is DuckDB SQL.

      evaluator_models()   in-scope models, typed by the naming-convention vars
      evaluator_sources()  in-scope sources
      evaluator_edges()    DAG edges between in-scope nodes (tests excluded), with both ends' attributes
#}

{# true unless the resource is excluded by `exclude_packages` / `exclude_paths_from_project` #}
{% macro evaluator_check_in_scope(alias) -%}
(
    coalesce({{ alias }}.package_name, '') not in ('dbt_project_evaluator'{% for package in var('exclude_packages', []) %}, '{{ package }}'{% endfor %})
    {%- for path in var('exclude_paths_from_project', []) %}
    and coalesce({{ alias }}.original_file_path, '') not like '%{{ path }}%'
    and {{ alias }}.unique_id not like '%{{ path | replace("/", "") }}%'
    {%- endfor %}
)
{%- endmacro %}


{% macro evaluator_directory(path) -%}
regexp_extract(replace({{ path }}, chr(92), '/'), '^(.*)/[^/]+$', 1)
{%- endmacro %}


{% macro evaluator_file_name(path) -%}
regexp_extract(replace({{ path }}, chr(92), '/'), '[^/]+$', 0)
{%- endmacro %}


{% macro evaluator_is_documented(column) -%}
(nullif(trim({{ column }}), '') is not null)
{%- endmacro %}


{# prefixes configured for a model type (the var may be a string or a list) #}
{% macro evaluator_prefixes(model_type) -%}
    {%- set prefixes = var(model_type ~ '_prefixes', []) -%}
    {{ return([prefixes] if prefixes is string else prefixes) }}
{%- endmacro %}


{#
    In-scope models with:
      prefix_model_type  type implied by the name prefix (null if none matches)
      folder_model_type  type implied by the deepest configured folder in the path (null if none)
      model_type         prefix, else folder, else 'other' (as in 1.x)
#}
{% macro evaluator_models() -%}
{%- set folders = {} -%}
{%- for model_type in var('model_types') if var(model_type ~ '_folder_name', none) -%}
    {%- do folders.update({var(model_type ~ '_folder_name'): model_type}) -%}
{%- endfor -%}
(
    select *, coalesce(prefix_model_type, folder_model_type, 'other') as model_type
    from (
        select model.*,
               {{ evaluator_directory('model.original_file_path') }} as directory_path,
               {{ evaluator_file_name('model.original_file_path') }} as file_name,
               {{ evaluator_is_documented('model.description') }} as is_documented,
               model.unique_id in (select unique_id from {{ info_schema('time_spines') }}) as is_time_spine,
               case
                   {%- for model_type in var('model_types') %}{% for prefix in evaluator_prefixes(model_type) %}
                   when starts_with(model.name, '{{ prefix }}') then '{{ model_type }}'
                   {%- endfor %}{% endfor %}
               end as prefix_model_type,
               {%- if folders %}
               case list_filter(
                   string_split({{ evaluator_directory('model.original_file_path') }}, '/'),
                   segment -> segment in ({% for folder in folders %}'{{ folder }}'{% if not loop.last %}, {% endif %}{% endfor %})
               )[-1]
                   {%- for folder, model_type in folders.items() %}
                   when '{{ folder }}' then '{{ model_type }}'
                   {%- endfor %}
               end as folder_model_type
               {%- else %}
               cast(null as varchar) as folder_model_type
               {%- endif %}
        from {{ info_schema('models') }} model
        where {{ evaluator_check_in_scope('model') }}
    )
)
{%- endmacro %}


{# in-scope sources, with `full_name` = source_name.table_name #}
{% macro evaluator_sources() -%}
(
    select source.*,
           source.source_name || '.' || source.name as full_name,
           {{ evaluator_directory('source.original_file_path') }} as directory_path,
           {{ evaluator_file_name('source.original_file_path') }} as file_name
    from {{ info_schema('sources') }} source
    where {{ evaluator_check_in_scope('source') }}
)
{%- endmacro %}


{#
    Direct edges between in-scope DAG nodes, tests excluded. For each end (parent_ / child_):
    unique_id, resource_type, name (source_name.table for sources), materialized, access and
    model_type (models only).
#}
{% macro evaluator_edges() -%}
(
    with nodes as (
        select unique_id, 'model' as resource_type,
               concat_ws('.v', name, nullif(cast(version as varchar), 'null')) as name,
               materialized, access, model_type
        from {{ evaluator_models() }}
        union all
        select unique_id, 'source', full_name, null, null, null
        from {{ evaluator_sources() }}
        {%- for view in ['seeds', 'snapshots'] %}
        union all
        select unique_id, resource_type, name, materialized, access, null
        from {{ info_schema(view) }} node where {{ evaluator_check_in_scope('node') }}
        {%- endfor %}
        {%- for view in ['exposures', 'metrics', 'saved_queries'] %}
        union all
        select unique_id, split_part(unique_id, '.', 1), name, null, null, null
        from {{ info_schema(view) }} node where {{ evaluator_check_in_scope('node') }}
        {%- endfor %}
    )
    select distinct
           {%- for side in ['parent', 'child'] %}
           {{ side }}.unique_id as {{ side }}_unique_id,
           {{ side }}.resource_type as {{ side }}_resource_type,
           {{ side }}.name as {{ side }}_name,
           {{ side }}.materialized as {{ side }}_materialized,
           {{ side }}.access as {{ side }}_access,
           {{ side }}.model_type as {{ side }}_model_type{% if not loop.last %},{% endif %}
           {%- endfor %}
    from {{ info_schema('edges') }} edge
    join nodes parent on parent.unique_id = edge.parent_unique_id
    join nodes child on child.unique_id = edge.child_unique_id
)
{%- endmacro %}


{# `<model_type>_<suffix>` columns: percentage of models of each type where `flag` holds #}
{% macro evaluator_pct_by_model_type(flag, suffix) -%}
    {%- for model_type in var('model_types') %}
    round(count(*) filter (where {{ flag }} and model_type = '{{ model_type }}') * 100.0
          / nullif(count(*) filter (where model_type = '{{ model_type }}'), 0), 2) as {{ model_type }}_{{ suffix }}
    {%- if not loop.last %},{% endif %}
    {%- endfor %}
{%- endmacro %}
