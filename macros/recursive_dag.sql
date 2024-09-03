{% macro recursive_dag() %}
    {{ return(adapter.dispatch('recursive_dag', 'dbt_project_evaluator')()) }}
{% endmacro %}

{% macro default__recursive_dag() %}

with recursive direct_relationships as (
    select
        *
    from {{ ref('int_direct_relationships') }}
    where resource_type <> 'test'
),

-- should this be a fct_ model?

-- recursive CTE
-- one record for every resource and each of its downstream children (including itself)
all_relationships (
    parent_id,
    parent,
    parent_resource_type,
    parent_model_type,
    parent_materialized,
    parent_access,
    parent_is_public,
    parent_source_name,
    parent_file_path,
    parent_directory_path,
    parent_file_name,
    parent_is_excluded,
    child_id,
    child,
    child_resource_type,
    child_model_type,
    child_materialized,
    child_access,
    child_is_public,
    child_source_name,
    child_file_path,
    child_directory_path,
    child_file_name,
    child_is_excluded,
    distance,
    path,
    is_dependent_on_chain_of_views
) as (
    -- anchor
    select distinct
        resource_id as parent_id,
        resource_name as parent,
        resource_type as parent_resource_type,
        model_type as parent_model_type,
        materialized as parent_materialized,
        access as parent_access,
        is_public as parent_is_public,
        source_name as parent_source_name,
        file_path as parent_file_path,
        directory_path as parent_directory_path,
        file_name as parent_file_name,
        is_excluded as parent_is_excluded,
        resource_id as child_id,
        resource_name as child,
        resource_type as child_resource_type,
        model_type as child_model_type,
        materialized as child_materialized,
        access as child_access,
        is_public as child_is_public,
        source_name as child_source_name,
        file_path as child_file_path,
        directory_path as child_directory_path,
        file_name as child_file_name,
        is_excluded as child_is_excluded,
        0 as distance,
        {{ dbt.array_construct(['resource_name']) }} as path,
        cast(null as {{ dbt.type_boolean() }}) as is_dependent_on_chain_of_views

    from direct_relationships
    -- where direct_parent_id is null {# optional lever to change filtering of anchor clause to only include root resources #}

    union all

    -- recursive clause
    select
        all_relationships.parent_id as parent_id,
        all_relationships.parent as parent,
        all_relationships.parent_resource_type as parent_resource_type,
        all_relationships.parent_model_type as parent_model_type,
        all_relationships.parent_materialized as parent_materialized,
        all_relationships.parent_access as parent_access,
        all_relationships.parent_is_public as parent_is_public,
        all_relationships.parent_source_name as parent_source_name,
        all_relationships.parent_file_path as parent_file_path,
        all_relationships.parent_directory_path as parent_directory_path,
        all_relationships.parent_file_name as parent_file_name,
        all_relationships.parent_is_excluded as parent_is_excluded,
        direct_relationships.resource_id as child_id,
        direct_relationships.resource_name as child,
        direct_relationships.resource_type as child_resource_type,
        direct_relationships.model_type as child_model_type,
        direct_relationships.materialized as child_materialized,
        direct_relationships.access as child_access,
        direct_relationships.is_public as child_is_public,
        direct_relationships.source_name as child_source_name,
        direct_relationships.file_path as child_file_path,
        direct_relationships.directory_path as child_directory_path,
        direct_relationships.file_name as child_file_name,
        direct_relationships.is_excluded as child_is_excluded,
        all_relationships.distance+1 as distance,
        {{ dbt.array_append('all_relationships.path', 'direct_relationships.resource_name') }} as path,
        case
            when
                all_relationships.child_materialized in ('view', 'ephemeral')
                and coalesce(all_relationships.is_dependent_on_chain_of_views, true)
                then true
            else false
        end as is_dependent_on_chain_of_views

    from direct_relationships
    inner join all_relationships
        on all_relationships.child_id = direct_relationships.direct_parent_id

    {% if var('max_depth_dag') | int > 0 %}
        {% if var('max_depth_dag') | int < 2 or var('max_depth_dag') | int < var('chained_views_threshold') | int %}
            {% do exceptions.raise_compiler_error(
                'Variable max_depth_dag must be at least 2 and must be greater or equal to than chained_views_threshold.'
                ) %}
        {% else %}
        where distance <= {{ var('max_depth_dag')}}
        {% endif %}
    {% endif %}

)

{% endmacro %}


{% macro bigquery__recursive_dag() %}

-- as of Feb 2022 BigQuery doesn't support with recursive in the same way as other DWs
{% set max_depth = var('max_depth_dag') | int %}
{% if max_depth < 2 or max_depth < var('chained_views_threshold') | int %}
    {% do exceptions.raise_compiler_error(
        'Variable max_depth_dag must be at least 2 and must be greater or equal to than chained_views_threshold.'
        ) %}
{% endif %}

with direct_relationships as (
    select
        *
    from {{ ref('int_direct_relationships') }}
    where resource_type <> 'test'
)

-- must do distinct prior to creating array because BigQuery doesn't support distinct on array type
, get_distinct as (
    select distinct
        resource_id as parent_id,
        resource_id as child_id,
        resource_name,
        materialized as child_materialized,
        is_public as child_is_public,
        access as child_access,
        is_excluded as child_is_excluded

    from direct_relationships
)

, cte_0 as (
    select
        parent_id,
        child_id,
        child_materialized,
        child_is_public,
        child_access,
        child_is_excluded,
        0 as distance,
        {{ dbt.array_construct(['resource_name']) }} as path,
        cast(null as {{ dbt.type_boolean() }}) as is_dependent_on_chain_of_views
    from get_distinct
)

{% for i in range(1,max_depth) %}
{% set prev_cte_path %}cte_{{ i - 1 }}.path{% endset %}
, cte_{{i}} as (
    select
        cte_{{i - 1}}.parent_id as parent_id,
        direct_relationships.resource_id as child_id,
        direct_relationships.materialized as child_materialized,
        direct_relationships.is_public as child_is_public,
        direct_relationships.access as child_access,
        direct_relationships.is_excluded as child_is_excluded,
        cte_{{i - 1}}.distance+1 as distance,
        {{ dbt.array_append(prev_cte_path, 'direct_relationships.resource_name') }} as path,
        case
            when
                cte_{{i - 1}}.child_materialized in ('view', 'ephemeral')
                and coalesce(cte_{{i - 1}}.is_dependent_on_chain_of_views, true)
                then true
            else false
        end as is_dependent_on_chain_of_views

        from direct_relationships
            inner join cte_{{i - 1}}
            on cte_{{i - 1}}.child_id = direct_relationships.direct_parent_id
)
{% endfor %}

, all_relationships_unioned as (
    {% for i in range(max_depth) %}
    select * from cte_{{i}}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

, resource_info as (
    select * from {{ ref('int_all_graph_resources') }}
)


, all_relationships as (
    select
        parent.resource_id as parent_id,
        parent.resource_name as parent,
        parent.resource_type as parent_resource_type,
        parent.model_type as parent_model_type,
        parent.materialized as parent_materialized,
        parent.is_public as parent_is_public,
        parent.access as parent_access,
        parent.source_name as parent_source_name,
        parent.file_path as parent_file_path,
        parent.directory_path as parent_directory_path,
        parent.file_name as parent_file_name,
        parent.is_excluded as parent_is_excluded,
        child.resource_id as child_id,
        child.resource_name as child,
        child.resource_type as child_resource_type,
        child.model_type as child_model_type,
        child.materialized as child_materialized,
        child.is_public as child_is_public,
        child.access as child_access,
        child.source_name as child_source_name,
        child.file_path as child_file_path,
        child.directory_path as child_directory_path,
        child.file_name as child_file_name,
        child.is_excluded as child_is_excluded,
        cast(all_relationships_unioned.distance as {{ dbt.type_int() }}) as distance,
        all_relationships_unioned.path,
        all_relationships_unioned.is_dependent_on_chain_of_views

    from all_relationships_unioned
    left join resource_info as parent
        on all_relationships_unioned.parent_id = parent.resource_id
    left join resource_info as child
        on all_relationships_unioned.child_id = child.resource_id
)

{% endmacro %}


{% macro clickhouse__recursive_dag() %}
    {{ return(bigquery__recursive_dag()) }}
{% endmacro %}

{% macro spark__recursive_dag() %}
-- as of June 2022 databricks SQL doesn't support "with recursive" in the same way as other DWs
    {{ return(bigquery__recursive_dag()) }}
{% endmacro %}


{% macro trino__recursive_dag() %}
{#-- Although Trino supports a recursive WITH-queries,
-- it is less performant than creating CTEs with loops and union them --#}
    {{ return(bigquery__recursive_dag()) }}
{% endmacro %}

{% macro athena__recursive_dag() %}
    {{ return(bigquery__recursive_dag()) }}
{% endmacro %}
